//
//  lock_slib_db.h
//  YCSB-C
//
//  Created by Jinglei Ren on 12/27/14.
//  Copyright (c) 2014 Jinglei Ren <jinglei@ren.systems>.
//

#ifndef YCSB_C_LOCK_SLIB_DB_H_
#define YCSB_C_LOCK_SLIB_DB_H_

#include "db/hashtable_db.h"

#include <string>
#include <vector>
#include "lib/lock_slib_hashtable.h"

namespace ycsbc {

class LockSLibDB : public HashtableDB {
 public:
  LockSLibDB() : HashtableDB(
      new vmp::LockSLibHashtable<HashtableDB::FieldHashtable *>) { }

  ~LockSLibDB() {
    std::vector<KeyHashtable::KVPair> key_pairs = key_table_->Entries();
    for (auto &key_pair : key_pairs) {
      DeleteFieldHashtable(key_pair.second);
    }
    delete key_table_;
  }

 protected:
  HashtableDB::FieldHashtable *NewFieldHashtable() {
    return new vmp::LockSLibHashtable<const char *>;
  }

  void DeleteFieldHashtable(HashtableDB::FieldHashtable *table) {
    std::vector<FieldHashtable::KVPair> pairs = table->Entries();
    for (auto &pair : pairs) {
      DeleteString(pair.second);
    }
    delete table;
  }

  const char *CopyString(const std::string &str) {
    char *value = new char[str.length() + 1];
    strcpy(value, str.c_str());
    return value;
  }

  void DeleteString(const char *str) {
    delete[] str;
  }
};

} // ycsbc

#endif // YCSB_C_LOCK_SLIB_DB_H_
