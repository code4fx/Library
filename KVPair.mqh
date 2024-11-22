//###<Experts/Template_System/Template_System.mq5>

class KVPairValueBase {
   public:
      virtual string typeName() = 0;
      virtual string toString() = 0; 

    string toString_(string value)     { return (value); }
    string toString_(int value)     { return IntegerToString(value); }
    string toString_(ulong value)     { return IntegerToString(value); }        
    string toString_(double value)     { return DoubleToString(value); }
    string toString_(datetime value)     { return TimeToString(value); }
    string toString_(bool value)     { return (string)(value); }
};

template <typename TValue>
class KVPairValue : public KVPairValueBase {
   public:
    TValue value_;
    KVPairValue(TValue value) { value_ = value; }
    string typeName() { return (typename(value_)); }
    TValue get() { return (value_); }
    string toString() { return (toString_(value_)); }
}; 

class KVPair {
    private:
        string key_;
        KVPairValueBase* value_;

    protected:
    public:
        template <typename TValue>
        KVPair(string key, TValue value)    { key_ = key; set(value); }
        ~KVPair() { if (value_ != NULL) delete value_; }

        template <typename TValue>
        TValue get()    { return ((KVPairValue<TValue>*)value_).get(); }

        template <typename TValue>
        void set(TValue value);

        string toString() { return (value_.toString()); }

        string getKey()     { return (key_); }
        string getType()        {return (value_.typeName()); }
};

template <typename TValue>
void KVPair::set(TValue value) {
    if (value_ != NULL)
        delete value_;
    value_ = new KVPairValue<TValue>(value);
}
