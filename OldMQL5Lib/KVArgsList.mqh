//###<Experts/Personal Projects/template_system/Template_System.mq5>
#include "KVPair.mqh"
#include <Generic/ArrayList.mqh>

class KVArgsList {
private:
    CArrayList<KVPair *> arr;
    int count;
public:
    KVArgsList() { count = 0; }
    ~KVArgsList() { arr.Clear(); }

    template <typename T>
    void addKeyVal(string, T);

    template <typename T>
    T getVal(string key);

    template <typename T>
    T getVal(int i);

    template <typename T>
    T operator[](string key);

     template <typename T>
    T operator[](int index);

    void delKeyVal(string key);
    string toString(int index);
    string toString(string key);
    int getSize() { return count; }
    string print();
};

string KVArgsList::toString(int index) {
    KVPair *temp = NULL;
    if (index >= 0 && index < count) {
        arr.TryGetValue(index, temp);
        return temp.toString();
    }
    return "";
}

string KVArgsList::toString(string key) {
    KVPair *temp = NULL;
    int s = arr.Count();
    for (int i = 0; i < s; i++) {
        arr.TryGetValue(i, temp);
        if (temp.getKey() == key)
            return temp.toString();
    }
    return "";
}

template <typename T>
void KVArgsList::addKeyVal(string key, T val) {
   arr.Add(new KVPair(key, val));
   count++;
}

template <typename T>
T KVArgsList::getVal(string key) {
    KVPair *temp = NULL;
    int s = arr.Count();
    for (int i = 0; i < s; i++) {
        arr.TryGetValue(i, temp);
        if (temp.getKey() == key)
            return temp.get<T>();
    }
    return NULL;
}

template <typename T>
T KVArgsList::operator[](string key) {
    return getVal(key);
}

template <typename T>
T KVArgsList::getVal(int index) {
    KVPair *temp = NULL;
    
    if (index >= 0 && index < count) {
        arr.TryGetValue(index, temp);
        return temp.get<T>();
    }
      
    return NULL;
}

template <typename T>
T KVArgsList::operator[](int index) {
    return getVal(index);
}

void KVArgsList::delKeyVal(string key) {
    KVPair *temp = NULL;
    int sz = arr.Count();
    for (int i = 0; i < sz; i++) {
        arr.TryGetValue(i, temp);
        if (temp.getKey() == key) {
            arr.RemoveAt(i);
            break;
        }
    }
    count++;
}

string KVArgsList::print() {
    KVPair *temp = NULL;
    int s = arr.Count();
    for (int i = 0; i < s; i++) {
        arr.TryGetValue(i, temp);
        Print(temp.getKey(), " : ", temp.toString());
    }
    return "";
}
