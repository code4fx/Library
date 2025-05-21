//+------------------------------------------------------------------+
//|                                                   GlobalVars.mqh |
//|                                         Copyright 2025, code4fx. |
//|                                          https://www.code4fx.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, code4fx."
#property link      "https://www.code4fx.com"
#property version   "1.00"

class CGlobalVars {

private:
	string m_masterKey;
	string m_keySep;
	int m_initStatus;
	double m_defaultVal;

    string KeyGen(string key);
	string MasterKeyGen(long acc, int magic_no, string symbol);

public:
	 CGlobalVars(int magic_number, string symbol, long account,  string keySep="_") {
	 	Init(magic_number, symbol, account, keySep);
	 }
	~CGlobalVars() {}
	void SetInitStatus(int init) { m_initStatus = init; }
	int GetInitStatus() { return m_initStatus; }
	void Init(int magic_number, string symbol, long account, string keySep="_", double defValue=-1);
	
	bool SetGlobalVar(string key, double value);
	double GetGlobalVar(string key);
};

void CGlobalVars::Init(int magic_number, string symbol, long account, string keySep="_", double defValue=-1) {
	
	m_keySep = keySep;
	m_defaultVal = defValue;
	
	m_masterKey = MasterKeyGen(account, magic_number, symbol);
	
	SetInitStatus(INIT_SUCCEEDED);
}

bool CGlobalVars::SetGlobalVar(string key, double value) {
//masterKey = account + symbol + magic
//key = name of variable
	string gvKey = m_masterKey + m_keySep + key;
	datetime result = GlobalVariableSet(gvKey, value);
	return (result > 0 ? true : false);
}

double CGlobalVars::GetGlobalVar(string key) {
	string gvKey = m_masterKey + m_keySep + key;
	double result = GlobalVariableCheck(gvKey) ?
					GlobalVariableGet(gvKey) :
					m_defaultVal;
	return result;
}

#ifdef __MQL4__
string CGlobalVars::MasterKeyGen(long acc, int magic_no, string symbol) {
	string mStr;
	mStr = StringConcatenate(acc, m_keySep, magic_no, m_keySep, symbol);
	return mStr;
}
string CGlobalVars::KeyGen(string key) {
	string str;
	str = StringConcatenate(m_masterKey, m_keySep, key);
	return str;
}
#endif

#ifdef __MQL5__
string CGlobalVars::MasterKeyGen(long acc, int magic_no, string symbol) {
	string mStr;
	StringConcatenate(mStr, acc, m_keySep, magic_no, m_keySep, symbol);
	return mStr;
}
string CGlobalVars::KeyGen(string key) {
	string str;
	StringConcatenate(str, m_masterKey, m_keySep, key);
	return str;
}
#endif
