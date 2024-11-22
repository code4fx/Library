//###<Experts/Template_System/Test.mq5>
//###<Experts/Template_System/Template_System.mq5>
//+------------------------------------------------------------------+
//|                                                VerboseObject.mqh |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Mojalefa."
#property link      "https://www.mql5.com"
#property strict

#include <ErrorDescription.mqh>

/**
 * File management wrapper class for working with CSV files.
 * Handles only 1 CSV file at a time. 
 * Therefore all files must be opened, operated on and closed
 * with respect to this order. 
*/

class CSVFileHandler {

private:
	int file_desc;
	string file_name;

	short sep_short;
	string sep_str;

	string file_arr[];
	int file_arr_size;

	void fillFileArray();

protected:
	bool pointToCell(const int col, const int row);
	
public:
	CSVFileHandler() { file_desc = -1; }
	~CSVFileHandler() { closeFile(); ArrayFree(file_arr); }
	int getFileDesciptor() { return file_desc; }
	string getFileName() { return file_name; }
	void setSeperator(string);

	bool openFile(const string file_name_, bool replace, const string);
	void closeFile();

	/**
	 * replaceLine - replaces the line at the specified row.
	*/
	void replaceLine(string &inArr[], const int row);

	/**
	 * eraseLine - erases the line at specified row.
	*/
	void eraseLine(const int row);

	/**
	 * appendLine - writes a line to the end of a file.
	*/
	void appendLine(string &inArr[]);

	/**
	 * readCell - reads the cell at the position specified by col and row.
	 * returns a string of the value in the cell.
	*/
	string readCell(const int col, const int row);

	/**
	 * readLine - reads the line specified by row,
	 * gives an array of the columns read at this row.
	 * returns number of columns read;
	*/
	int readLine(string &outArr[], const int row);
};

void CSVFileHandler::setSeperator(string sep_) {
	
	sep_short = (short)(StringGetCharacter(sep_, 0));
	sep_str = sep_;
}

bool CSVFileHandler::openFile(const string file_name_, bool replace = false, const string sep_ = ",") {

	setSeperator(sep_);
	
	int modes = FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI;
	string ext = ".csv";
	string name = file_name_+ext;
	file_name = name;

	if (file_desc != -1) {
		print_error("some file is already open", __FUNCTION__);
		return false;
	}
	
	if (replace && FileIsExist(name)) {
		if (!FileDelete(name)) {
			print_error("file could not be replaced", __FUNCTION__);
			return false;
		}
	}
	
	file_desc = FileOpen(name, modes, sep_short);

	if (file_desc < 0) {
		print_error(__FUNCTION__);
		return false;
	}

	return true;
}

void CSVFileHandler::closeFile(void) {
	if(file_desc != -1) {
		FileClose(file_desc);
		file_desc = -1;
		file_name = "";
	}
}

void CSVFileHandler::fillFileArray(void) { 

	ArrayFree(file_arr);
	int arr_size = ArraySize(file_arr);
	string str = "";
	
	if (file_desc == -1) {
		print_error("file not open", __FUNCTION__);
		return;
	}
	
	if (!pointToCell(0, 0)) {
		print_error("file could point to the cell at col = "+IntegerToString(0)+
					" and row = "+IntegerToString(0),
					 __FUNCTION__);
		return;
	}

	do {
		str = "";

		do {
			str += FileReadString(file_desc);
			str += FileIsLineEnding(file_desc) ? "": sep_str;
		} while (!FileIsLineEnding(file_desc));

		ArrayResize(file_arr, arr_size + 1);
		file_arr[arr_size++] = str;

	} while (!FileIsEnding(file_desc));
}

void CSVFileHandler::appendLine(string &inArr[]) {

	int arr_size; 
	uint bytes = 0;

	if (file_desc == -1) {
		print_error("file not open", __FUNCTION__);
		return;
	}

	while(!FileIsEnding(file_desc))
		FileReadString(file_desc);

	arr_size = ArraySize(inArr);  
	
	for(int i = 0; i < arr_size; i++) {
		if(i < arr_size - 1)
			bytes += FileWriteString(file_desc, inArr[i]+sep_str);
		else
			bytes += FileWriteString(file_desc, inArr[i]);
	}
	
	bytes += FileWriteString(file_desc, "\r\n");

	if (bytes == 0) {
		print_error("could not print items to file", __FUNCTION__);
	}	
}

int CSVFileHandler::readLine(string &outArr[], const int row) {
	
	string str  = "";
	int arr_size = ArraySize(outArr);

	if (arr_size != 0) {
		print_error("empty array argument expected", __FUNCTION__);
		return 0;
	}

	if (file_desc == -1) {
		print_error("file not open", __FUNCTION__);
		return 0;
	}
	
	if (!pointToCell(0, row)) {
		print_error("file could point to the cell at col = "+IntegerToString(0)+
					" and row = "+IntegerToString(row),
					 __FUNCTION__);
		return 0;
	}

	do {
		ArrayResize(outArr, arr_size + 1);
		outArr[arr_size++] = FileReadString(file_desc);
	} while (!FileIsLineEnding(file_desc));
	
	return arr_size;
}

string CSVFileHandler::readCell(const int col, const int row) {
	
	string str  = "";

	if (file_desc == -1) {
		print_error("file not open", __FUNCTION__);
		return "";
	}
	
	if (!pointToCell(col, row)) {
		print_error("file could point to the cell at col = "+IntegerToString(col)+
					" and row = "+IntegerToString(row),
					 __FUNCTION__);
		return "";
	}

	str = FileReadString(file_desc);
	
	return str;
}

bool CSVFileHandler::pointToCell(const int col, const int row) {

	string str = "";
	string str_arr[];
	int arr_size = 0;

	if (file_desc == -1) {
		print_error("file not open", __FUNCTION__);
		return false;
	}
	
	FileSeek(file_desc, 0, SEEK_SET);
	
	for (int i = 0; i < row; i++) {
		do {
			FileReadString(file_desc);
		} while (!FileIsLineEnding(file_desc));
	}

	int j;
	for (j = 0; j < col; j++) {
		FileReadString(file_desc);
		if (FileIsLineEnding(file_desc))
			return false;
	}

	if (FileIsEnding(file_desc)) {
		return false;
	}

	return true;
}

void CSVFileHandler::replaceLine(string &inArr[], const int row) {
	
	int arr_size = 0, in_size;
	string str = "", fn = "";
	
	fillFileArray();
	
	arr_size = ArraySize(file_arr);

	if (arr_size <= 0) {
		print_error("could not fill file array", __FUNCTION__);
		return;
	}

	if (row < 0 || row >= arr_size) {
		print_error("row is out of range", __FUNCTION__);
		return;
	}

	in_size = ArraySize(inArr);
	for (int i = 0; i < in_size; i++) {
		str += inArr[i];
		str += (i == in_size - 1) ? "" : sep_str;
	}

	file_arr[row] = str;

	fn = getFileName();
	closeFile();

	if (!FileDelete(fn)) {
		print_error("could not delete file named ["+fn+"]", __FUNCTION__);
		return;
	}

	if (!openFile(fn)) {
		print_error("file could not be opened", __FUNCTION__);
		return;
	}

	for (int j = 0; j < arr_size; j++) {
		FileWriteString(file_desc, file_arr[j]+"\r\n");
	}
}

void CSVFileHandler::eraseLine(const int row) {
	
	int arr_size = 0;
	string str = "", fn = "";
	
	fillFileArray();
	
	arr_size = ArraySize(file_arr);

	if (arr_size <= 0) {
		print_error("could not fill file array", __FUNCTION__);
		return;
	}

	if (row < 0 || row >= arr_size) {
		print_error("row is out of range", __FUNCTION__);
		return;
	}

	string new_arr[];

	if (row == 0) {
		ArrayCopy(new_arr, file_arr, 0, 1);
	}
	else if (row == arr_size - 1) {
		ArrayCopy(new_arr, file_arr, 0, 0, arr_size - 1);
	}
	else {
		ArrayCopy(new_arr, file_arr, 0, 0, row);
		ArrayCopy(new_arr, file_arr, row, row + 1);
	}

	fn = getFileName();
	closeFile();

	if (!FileDelete(fn)) {
		print_error("could not delete file named ["+fn+"]", __FUNCTION__);
		print_error(__FUNCTION__);
		return;
	}

	if (!openFile(fn)) {
		print_error("file could not be opened", __FUNCTION__);
		return;
	}
	
	for (int j = 0; j < arr_size - 1; j++) {
		FileWriteString(file_desc, new_arr[j]+"\r\n");
	}

	ArrayFree(new_arr);
}
