#! /bin/sh

find . -type f -exec sed -i "s/\"sst_config.h\"/<sst\/core\/sst_config.h>/g" {} \;
sed -i "s/\"output.h\"/<sst\/core\/output.h>/g" c_BankCommand.hpp
sed -i "s/<output.h>/<sst\/core\/output.h>/g" c_Transaction.hpp

ed -s c_TxnConverter.hpp << 'EOF'
0a
// clang-format off
.
$a
// clang-format on
.
w
EOF
