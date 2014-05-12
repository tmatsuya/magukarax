#!/usr/bin/awk -f
BEGIN {
    IDLE  = "07"
    START = "fb"
    STOP  = "fd"
    count = 0
}
{
    data[count] = $1
    count = count + 1
    if (count >= 8) {
        count = 0
        if (data[0]==55 && data[1]==55 && data[2]==55 && data[3]==55 && data[4]==55 && data[5]==55 && data[6]==55 && data[7]="d5") {
            data[8] = "01"
            data[0] = START
        } else {
            data[8] = "00"
        }
        print data[8] "_" data[7] "_" data[6] "_" data[5] "_" data[4] "_" data[3] "_" data[2] "_" data[1] "_" data[0]
    }
}
END {
    if (count == 0) {
        print "ff_07_07_07_07_07_07_07_" STOP
    } else if (count == 1) {
        print "fe_" IDLE "_" IDLE "_" IDLE "_" IDLE "_" IDLE "_" IDLE "_" STOP "_" data[0]
    } else if (count == 2) {
        print "fc_" IDLE "_" IDLE "_" IDLE "_" IDLE "_" IDLE "_" STOP "_" data[1] "_" data[0]
    } else if (count == 3) {
        print "f8_" IDLE "_" IDLE "_" IDLE "_" IDLE "_" STOP "_" data[2] "_" data[1] "_" data[0]
    } else if (count == 4) {
        print "f0_" IDLE "_" IDLE "_" IDLE "_" STOP "_" data[3] "_" data[2] "_" data[1] "_" data[0]
    } else if (count == 5) {
        print "e0_" IDLE "_" IDLE "_" STOP "_" data[4] "_" data[3] "_" data[2] "_" data[1] "_" data[0]
    } else if (count == 6) {
        print "c0_" IDLE "_" STOP "_" data[5] "_" data[4] "_" data[3] "_" data[2] "_" data[1] "_" data[0]
    } else if (count == 7) {
        print "80_" STOP "_" data[6] "_" data[5] "_" data[4] "_" data[3] "_" data[2] "_" data[1] "_" data[0]
    }
}

