\ Model cell_tower
\ LP format - for model browsing. Use MPS format to capture full model detail.
Maximize
  523 Is_covered[0] + 690 Is_covered[1] + 420 Is_covered[2]
   + 1010 Is_covered[3] + 1200 Is_covered[4] + 850 Is_covered[5]
   + 400 Is_covered[6] + 1008 Is_covered[7] + 950 Is_covered[8]
Subject To
 Build2cover[0]: - Is_covered[0] + Build[0] + Build[1] + Build[4] >= 0
 Build2cover[1]: - Is_covered[1] + Build[0] >= 0
 Build2cover[2]: - Is_covered[2] + Build[2] + Build[3] + Build[4] >= 0
 Build2cover[3]: - Is_covered[3] + Build[2] + Build[5] >= 0
 Build2cover[4]: - Is_covered[4] + Build[2] + Build[5] >= 0
 Build2cover[5]: - Is_covered[5] + Build[0] + Build[3] >= 0
 Build2cover[6]: - Is_covered[6] + Build[2] + Build[3] + Build[4] >= 0
 Build2cover[7]: - Is_covered[7] + Build[1] + Build[4] >= 0
 Build2cover[8]: - Is_covered[8] + Build[1] + Build[4] + Build[5] >= 0
 budget: 4.2 Build[0] + 6.1 Build[1] + 5.2 Build[2] + 5.5 Build[3]
   + 4.8 Build[4] + 9.2 Build[5] <= 20
Bounds
Binaries
 Is_covered[0] Is_covered[1] Is_covered[2] Is_covered[3] Is_covered[4]
 Is_covered[5] Is_covered[6] Is_covered[7] Is_covered[8] Build[0] Build[1]
 Build[2] Build[3] Build[4] Build[5]
End
