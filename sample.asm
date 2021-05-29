0: CPi 70 1000 //reset data at address 70 to 1000
1: CP 100 1022 //read number from switches at address 1022
2: CP 69 102 // reset data at address 69 to 1
3: NAND 69 69 // 1's complement of 1                   
4: ADDi 69 1 // 2's complement of 1 [69: -1]         
5: CPIi 70 100 // loc 1000 -> n 
6: ADD 100 69 // n - 1
7: CP 71 100 // 71 -> n - 1
8: LTi 71 1 // n - 1 < 1 
9: ADDi 70 1 // loc 1000 ++ 
10: BZJ 72 71 // if n-1 > 1 go to loc 2 (72:2) else go to loc 8
11: ADD 70 69 // (1000 + n) - 1
12: CPI 74 70 // 74 -> # go to loc (1000 + n) - 1
13: CP 75 70 // 75:loc (1000 + n) - 1
14: ADD 75 69 // [(1000 + n) - 1] -- 
15: CPI 76 75 // 76: # at loc [(1000 + n) - 1] -- 
16: MUL 76 74 // 1.2 --> 2.3 --> 6.4 --> (n-1)!.n
17: CP 74 76 // save result 
18: CP 77 75 // 77: loc loc (1000 + n) - 1
19: LTi 77 1001 // check that all n numbers multiplied 
20: BZJ 73 77 // if 1000 loc stop else continue
21: CP 101 76 // copy result to loc 101 
22: BZJi 23 22 // infinite loop END
23: 0
69: 1 // [-1]
70: 1000 // Stack start # 
72: 5 // first loop location
73: 14 // second loop location 
100: 6 // INPUT n 
101: 0 // RESULT
102: 1
999: 1