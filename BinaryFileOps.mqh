//###<Experts/Template_System/Test.mq5>
//+------------------------------------------------------------------+
//|                                                VerboseObject.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Mojalefa."
#property link      "https://www.mql5.com"
#property strict

#include <System_Templates/ErrorDescriptions.mqh>

template <typename T>
class BinaryFileOps {
    
private:
    T   bin_struct_arr[];
    int file_descriptor;
    int bin_struct_size;
    string  file_name_;
    bool init_status_;

public:
    BinaryFileOps() { bin_struct_size = sizeof(T); init_status_ = false; }
    BinaryFileOps(string file_name) { 
        bin_struct_size = sizeof(T); 
        if (!openFile(file_name_, true))
            init_status_ = false;
        else
            init_status_ = true;
    }
    
    ~BinaryFileOps() { 
        FileClose(file_descriptor);
        FileDelete(file_name_);
        ArrayFree(bin_struct_arr);
    }

    bool             openFile(string file_name, bool replace=false);
    bool             initBinFileOps(string);
 
    bool             contains(ulong pos_id, int &index);
    void             write(T&);
    void             write(T& data[]);
    void             read(int index, T&);
    void             read(T& data[]);
    void             update(int index, T&);
    void             erase(int index);
    int              getCount();
    void             printFile();
    
};

template <typename T>
bool BinaryFileOps::openFile(string file_name, bool replace) {

    if (StringFind(file_name, ".bin") == -1)
        file_name_ = file_name + ".bin";
    else
        file_name_ = file_name;
    
    if (replace == true && FileIsExist(file_name_)) {
       if (!FileDelete(file_name_)) {
            print_error("Could not delete file", __FUNCTION__);
            return false; 
       }
    }

    int modes = FILE_WRITE|FILE_READ|FILE_BIN;
    file_descriptor = FileOpen(file_name_, modes);
   
    if (file_descriptor == INVALID_HANDLE) {
        print_error(__FUNCTION__);
        return false;
    }
    else {
        return true;
    }
}

template <typename T>
bool BinaryFileOps::initBinFileOps(string file_name) {
    
    if (!openFile(file_name_)) {
        init_status_ = false;
        return false;
    }
    
    init_status_ = true;
    return true;
}

template <typename T>
bool BinaryFileOps::contains(ulong pos_id, int& index) {

    index = -1;

    if (!FileSeek(file_descriptor, 0, SEEK_SET)) {
        print_error(__FUNCTION__);
        return false;
    }

    T arr[];
    
    FileReadArray(file_descriptor, arr);
  
    int size = getCount();

    for (int i = 0; i < size; i++) {
        if (arr[i].position_id == pos_id) {
            index = i;
            return true;
        }
    }

    return false;
}

template <typename T>
void BinaryFileOps::update(int index, T& data) {

    int size = getCount();

    if ((index < 0) || (index >= size)) {
        print_error("index is out of range", __FUNCTION__);
        return;
    }

    if (!FileSeek(file_descriptor, 0, SEEK_SET)) {
        print_error(__FUNCTION__);
        return;
    }

    T arr[];

    if (FileReadArray(file_descriptor, arr) <= 0) {
        print_error("could not read elements from file", __FUNCTION__);
        return;
    }

    arr[index] = data;
}

template <typename T>
void BinaryFileOps::write(T& data) {
    
    if (!FileSeek(file_descriptor, 0, SEEK_END)) {
        print_error(__FUNCTION__);
        return;
    }

    if (FileWriteStruct(file_descriptor, data) == 0) {
        print_error("could not write to file", __FUNCTION__);
        return;
    }
}

template <typename T>
void BinaryFileOps::write(T& data[]) {
    
    if (FileWriteArray(file_descriptor, data) == 0) {
        print_error("could not write array to file", __FUNCTION__);
        return;
    }
}

template <typename T>
void BinaryFileOps::read(int index, T& data) {
    
    int size = getCount();

    if ((index < 0) || (index >= size)) {
        print_error("index is out of range", __FUNCTION__);
        return;
    }

    if (!FileSeek(file_descriptor, (index * bin_struct_size), SEEK_SET)) {
        print_error(__FUNCTION__);
        return;
    }

    if (FileReadStruct(file_descriptor, data) <= 0) {
        print_error("could not read from file", __FUNCTION__);
        return;
    }
}

template <typename T>
void BinaryFileOps::read(T& data[]) {

    if (FileReadArray(file_descriptor, data) == 0) {
        print_error("could not read array from file", __FUNCTION__);
        return;
    }
}

template <typename T>
void BinaryFileOps::erase(int index) {

    int size = getCount();

    if ((index < 0) || (index >= size)) {
        print_error("index is out of range", __FUNCTION__);
        return;
    }

    if (!FileSeek(file_descriptor, 0, SEEK_SET)) {
        print_error(__FUNCTION__);
        return;
    }

    T arr[], temp[];

    if (FileReadArray(file_descriptor, arr) <= 0) {
        print_error("could not read elements from file", __FUNCTION__);
        return;
    }

    if (index == 0) {
        ArrayCopy(temp, arr, 0, 1);
    }
    else if (index == size - 1) {
        ArrayCopy(temp, arr, 0, 0, size - 1);
    }
    else {
        ArrayCopy(temp, arr, 0, 0, index);
        ArrayCopy(temp, arr, index, index + 1);
    }

    FileClose(file_descriptor);
    FileDelete(file_name_);
    openFile(file_name_);

    if (!FileSeek(file_descriptor, 0, SEEK_SET)) {
        print_error(__FUNCTION__);
        return;
    }

    if (FileWriteArray(file_descriptor, temp) <= 0) {
        print_error("could not write elements to file", __FUNCTION__);
        return;
    }
}

template <typename T>
int BinaryFileOps::getCount() {
    ulong fsize = FileSize(file_descriptor);
    int size = ((int)fsize / bin_struct_size);
    return (size);
}

template <typename T>
void BinaryFileOps::printFile() {
    
    int size;
    T temp[], tempr;

    if (!FileSeek(file_descriptor, 0, SEEK_SET)) {
        print_error(__FUNCTION__);
        return;
    }

    if (FileReadArray(file_descriptor, temp) == 0) {
        print_error("could not read elements from file", __FUNCTION__);
        return;
    }

    size = ArraySize(temp);

    for (int i = 0; i < size; i++) {
        Print(temp[i].print());
    }
}

//+------------------------------------------------------------------+