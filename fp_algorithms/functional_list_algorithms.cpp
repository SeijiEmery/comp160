//
// Created by Seiji Emery 9/8/16
// All rights reserved.
//

template <class T>
class RCBaseObject {
    int16_t _rc = 0;
    bool    _released = false;

    RCBaseObject () {}
    // virtual ~RCBaseObject () {}
public:
    template <typename... Args>
    static T* create (Args... args) { return new T(args...); }

    static T* rcRetain (T* obj) {
        return obj && static_cast<RCBaseObject<T>*>(obj)->drc() ? ((delete obj), nullptr) : obj;
    }
    static T* rcRelease (T* obj) {
        return (obj && static_cast<RCBaseObject<T>*>(obj)->irc()), obj;
    }
    static int rcCount (T* obj) {
        return obj ? static_cast<RCBaseObject<T>*>(obj)->getRc() : -1;
    }

private:
    void irc () { ++_rc; }
    bool drc () {
        if (--_rc < 0 && !_released)
            return _released = true;
        return false;
    }
    int getRc () { return _rc; }
};

template <typename T>
T* retain (T* x) { return RCBaseObject<T>::rcRetain(x); }

template <typename T>
T* release (T* x) { return RCBaseObject<T>::rcRelease(x); }

template <typename T>
int rcCount (T* x) { return RCBaseObject<T>::rcCount(x); }


template <typename T>
struct Cons : RCBaseObject<Cons<T>> {
    T        car;
    Cons<T>* cdr;

    Cons (T car = nullptr, Cons<T>* cdr = nullptr) :
        car(retain(car)), cdr(retain(cdr)) {}

    // When released, recursively release all following elements.
    ~Cons () {
        car = release(car);
        cdr = release(cdr);
    }
};

template <typename T>
T reduce (
    RCContext* ctx,
    T (*fcn)(RCContext*, T, T),
    T head,
    Cons<T>* list,
) {
    while (list) {
        head = retain(fcn(ctx, head, list->car));
        list = list->cdr;
    }
    return head;
}

template <typename T>
uint32_t length (
    RCContext* ctx,
    Cons<T>* list,
) {
    uint32_t len = 0;
    while (list) {
        list = list->cdr;
        ++len;
    }
    return len;
}

template <typename T>
Cons<T>* map (
    RCContext* ctx,
    Cons<T>* list,
    T (*fcn)(RCContext*, T),
) {
    if (!list)
        return nullptr;

    Cons<T>* l2 = retain(Cons<T>::alloc(ctx));
    Cons<T>* head = l2;
    
    head->car = retain(fcn(ctx, list->car));
    while (list->cdr) {
        head = head->cdr = retain(Cons<T>::alloc(ctx));
        head->car        = retain(fcn(ctx, list->car));
        list             = list->cdr;
    }
    return l2;
}

// Helper function: return first element from list that matches pred, or null.
// Used to implement filter.
template <typename T>
T findNextValue (RCContext* ctx, bool (*pred)(RCContext*, T), Const<T>*& list) {
    while (list && !pred(ctx, list->car))
        list = list->cdr;

    return list ?
        list->car : nullptr;
}


template <typename T>
Cons<T>* filter (
    RCContext* ctx,
    Cons<T>*   list,
    bool (*pred)(RCContext*, T),
) {
    T value = findNextValue(ctx, pred, list);
    if (!value)
        return nullptr;

    Cons<T>* l2 = retain(Cons<T>::alloc(ctx));
    Cons<T>* head = l2;

    head->car = value;
    list  = list->cdr;

    while ((value = findNextValue(ctx, pred, list)) != nullptr) {
        head = head->cdr = retain(Cons<T>::alloc(ctx));
        head->car = retain(value);
        list = list->cdr;
    }
    return l2;
}

// Returns a pointer to the nth segment of the list, or null (empty list)
// if the passed in list was null, or index exceeds the list bounds.
template <typename T>
Cons<T>* getListAtIndex (
    RCContext* ctx,
    Cons<T>*   list,
    int32_t    index = 0
) {
    // Resolve negative indices to offsets from back
    if (index < 0)
        index = static_cast<typeof(index)>(length(ctx,list)) + index;
    assert(index >= 0);

    // Advance list to nth element + return
    while (list && index != 0) {
        list = list->cdr;
        --index;
    }
    return list;
}

// Returns a pointer to the last segment of the list,
// or null (empty list) if the passed in list was null.
template <typename T>
Cons<T>* tail (
    RCContext* ctx,
    Cons<T>*   head,
) {
    if (!head)
        return nullptr;

    while (head->cdr)
        head = head->cdr;
    return head;
}

template <typename T>
T setValue (
    RCContext* ctx,
    Cons<T>*   list,
    T          value,
    int32_t   index = 0
) {
    list = getListAtIndex(ctx, list, index);
    if (!list)
        return null;

    // Release old value + assign + retain new value.
    release(list->car);
    return list->car = retain(value);
}

template <typename T>
T getValue (
    RCContext* ctx,
    Cons<T>*   list,
    int32_t   index = 0
) {
    list = getListAtIndex(ctx, list, index);
    return list ?
        list->car : nullptr;
}

// Inserts one list (b) into another (a) at the given index (may be negative,
// in which case an offset from the end is used).
template <typename T>
Cons<T>* insert (
    RCContext* ctx,
    Cons<T>* a,
    Cons<T>* b,
    int32_t  index
) {
    auto a_head = a;
    if (!b || !(a = getListAtIndex(ctx, a, index)))
        return nullptr;

    auto a_tail = a->cdr;
    auto b_tail = tail(ctx, b);
    assert(b_tail != nullptr);

    a->cdr      = retain(b);
    b_tail->cdr = a_tail;
    return a_head;
}

// Returns a list slice using the range (index,end,inc):
// – all items on [index,end], clamped to [0, length)
// - if inc != 1, selects every nth item (inc).
// - if inc < 0, returns a reversed slice with inc = abs(inc).
// - inc = 0 is invalid and will return an empty list.
//
// The (new) slice is always duplicated and does not point
// to any cons elements of the original list. Note: this is to
// preserve functional language semantics; we would only create
// a reference to the original list (better performance) iff
// we had a copy-on-write data structure, which is beyond our
// original scope (create a trivial, simple implementation of fp
// data structures).
//
// Calling slice(0,-1,1) is equivalent to just duplicating
// the original list.
// 
template <typename T>
Cons<T>* slice (
    RCContext* ctx,
    Cons<T>*   list,
    int32_t    index,
    int32_t    end = -1,
    int32_t    inc = 1
) {
    if (!list)
        return nullptr;

    // Resolve indices
    auto len = static_cast<int32_t>(length(ctx,list));

    if (index < 0)         index = len - index;
    else if (index >= len) index = len - 1;

    if (end < 0)           end = len - end;
    else if (end >= len)   end = len - 1;

    if (inc < 0)
        swap(index, end);

    if (inc == 0)
        return nullptr;

    // Advance to first element:
    auto list_head = list;
    list = getListAtIndex(ctx, list, index);
    if (!list)
        return nullptr;

    auto l2 = retain(Cons<T>::alloc(ctx));
    auto head = l2;

    head->car = retain(list->car);

    if (inc > 0) {
        // Increment is positive, so can just scan forwards through the list
        while ((index += inc) <= end) {
            list = getListAtIndex(ctx, list, inc);
            if (list) {
                head = head->cdr = retain(Cons<T>::alloc(ctx));
                head->car = retain(list->car);
            } else break;
        }
    } else {
        // Increment is negative (reverse). Since we cannot scan backwards
        // (singly linked list), we must re-seek each call.
        while ((index += inc) <= end) {
            list = getListAtIndex(ctx, list_head, index);
            if (list) {
                head = head->cdr = retain(Cons<T>::alloc(ctx));
                head->car = retain(list->car);
            } else break;
        }
    }
    return l2;
}

// Delete all values in range. This is a _destructive_ operation.
// Note: for non-destructive,
//  a) duplicate list (eg. slice(0,-1,1))
//  b) call deleteRange.
template <typename T>
Cons<T>* deleteRange (
    RCContext* ctx,
    Cons<T>*   list,
    int32_t    index,
    int32_t    end = -1,
) {
    if (!list) return nullptr;

    auto len = static_cast<int32_t>(length(ctx,list));

    // Resolve negative indices + clamp indices to [0,len)
    if (index < 0)         index = len - index;
    else if (index >= len) index = len - 1;
    if (end < 0)           end = len - end;
    else if (end >= end)   end = len - 1;

    if (index >= end) {
        // Special case #1: if index >= end, should not delete anything (just return list)
        return list;
    }

    if (index == 0) {
        // Special case #2: we want to delete the first index (our list head),
        // and everything up to end.

        if (end == len-1) {
            // Special case #3: if we called deleteRange(0,-1), we should just
            // delete everything (free list) and return null. Note: null list 
            // _should_ be handled as a valid argument by all other fcns...

            release(list);
            return nullptr;
        }
        // Otherwise...

        // Grab a pointer to the node _before_ the one at end
        auto tailp = getListAtIndex(ctx, list, end-1);

        // tailp _should_ exist: 
        // a) len == 0 => returned early.
        // b) end == 0 => end >= len, returned early.
        assert(tailp);

        // Set our list node to tail (tailp->cdr; may be null) + store the original head in a temp.
        auto head = list;
        list = tailp->cdr;

        // Break the chain from head -> tailp (so we don't release tail onwards), and release head.
        tailp->cdr = nullptr;
        release(head);

    } else {
        // Grab node before head (may be list itself), and node before tail using index/end indices.
        auto headp = getListAtIndex(ctx, list, index-1);
        auto tailp = getListAtIndex(ctx, list, end-1);

        // Check the following preconditions:
        // – non-null headp: index bounded by [0,N), so index-1 either positive or -1 (list head).
        // - non-null tailp: end   bounded by [0,N), so end-1   either positive or -1 (list head).
        // - headp != tailp: headp == tailp iff index-1 == end-1; handled by case #1.
        assert(headp && tailp && headp != tailp);

        // Break chain so we can release head..tailp.
        auto tail  = tailp->cdr;
        tailp->cdr = nullptr;
        release(headp->cdr);

        // Rejoin headp to tail (may be null).
        headp->cdr = tail;
    }
    return list;
}

