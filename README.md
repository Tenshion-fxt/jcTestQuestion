# 测试题1

Python代码见`jcTestQuestion\1`

# 测试题2

SQL查询见`jcTestQuestion\2`

# 测试题3

数据模型见`jcTestQuestion\3`

## 表说明

除去题目要求的五个表，考虑到“锦标赛可以有零个、一个或多个赞助方” 以及 “棋手可以参加零次或多次锦标赛”，如果直接在表`Tournaments`中用一个字段来表示“多个赞助商”或“多个棋手”，会导致严重的数据冗余和操作困难，而且违反了数据库的第一范式。

因此，额外建立了表`Sponsors`独立存储所有赞助商的唯一信息,并使用表`Tournament_Sponsors`和表`Tournament_Sponsors`解决“锦标赛”和“赞助方”、“棋手”之间的多对多关系。
