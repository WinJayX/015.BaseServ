/*
 * Copyright 1999-2018 Alibaba Group Holding Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/******************************************/
/*     创建canal用户                      */
/******************************************/
# 创建用户名与密码都为canal的用户。
CREATE USER canal IDENTIFIED BY 'canal';
# 授权
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'canal'@'%';
FLUSH PRIVILEGES;



/******************************************/
/*     创建超级用户                       */
/******************************************/
/*
# 创建用户名与密码都为canal的用户。
CREATE USER SuperUser IDENTIFIED BY 'P@88W0rd';
# 授权
GRANT ALL PRIVILEGES ON *.* TO 'SuperUser'@'%' WITH GRANT OPTION;;
FLUSH PRIVILEGES;

*/
