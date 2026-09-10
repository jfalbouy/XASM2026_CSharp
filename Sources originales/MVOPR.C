#include "xasm.h"

unsigned char mv_operand(mvflag, pnt)
unsigned char mvflag;
int *pnt;
{
   unsigned char oprtxt[255];
   unsigned char gid_1, gid_2, id_1, id_2;
   unsigned char op1_1, op1_2, op2_1, op2_2, op3_1, op3_2;
   int err;
   get_operand(pnt,oprtxt);
   if (asmtext[*pnt-1] == ',') {
      err = evalx(oprtxt,&gid_1,&id_1,&op1_1,&op2_1,&op3_1);
      if (err == 0) {
         (*pnt)++;
         get_operand(pnt,oprtxt);
         if (asmtext[*pnt-1] != ',') {
            err = evalx(oprtxt,&gid_2,&id_2,&op1_2,&op2_2,&op3_2);
            if (err == 0) {
               if (gid_1 == 1) {
                  if (mvflag != 0) {
                     err = 7;
                  } else {
                     switch (gid_2) {
                        case 0:
                           if (id_1 <= 7) {
                              set_op(8 + id_1);
                              set_reg_opecode(id_1,op1_2,op2_2,op3_2);
                           } else {
                              err = 7;
                           }
                           break;
                        case 1:
                           if ((id_1 <= 7)&&(id_2 <= 7)) {
                              set_op(253);  set_op(id_1 * 16 + id_2);
                           } else if ((id_1 == 0)&&(id_2 == 8)) {
                              set_op(116);
                           } else if ((id_1 == 8)&&(id_2 == 0)) {
                              set_op(117);
                           } else {
                              err = 7;
                           }
                           break;
                        case 2:
                           if (id_1 <= 7) {
                              err = prebyte(id_2,0);
                              set_op(128 + id_1);  set_op(op1_2);
                           } else {
                              err = 7;
                           }
                           break;
                        case 3:
                           if (id_1 <= 7) {
                              switch (id_2) {
                                 case 0:
                                    set_op(136 + id_1);  set_op(op1_2);
                                    set_op(op2_2);       set_op(op3_2);
                                    break;
                                 case 1:  case 2:  case 3:  case 4:  case 5:
                                    if ((id_1 <= 6)&&(op1_2 <= 7)) {
                                       set_op(144 + id_1);
                                       set_r3_opecode(id_2,op1_2,op2_2);
                                    } else {
                                       err = 7;
                                    }
                                    break;
                                 case 6:  case 7:  case 8:
                                    if (id_1 <= 6) {
                                       err = prebyte(op1_2,0);
                                       set_op(152 + id_1);
                                       set_r3_opecode(id_2,op2_2,op3_2);
                                    } else {
                                       err = 7;
                                    }
                                    break;
                              }
                           }
                           break;
                        default:
                           err = 7;
                           break;
                     }
                  }
               } else if (gid_1 == 2) {
                  switch (gid_2) {
                     case 0:
                        err = prebyte(id_1,0);
                        if ((err == 0)&&(mvflag <= 2)) {
                           switch (mvflag) {
                              case 0:  set_op(204);  break;
                              case 1:  set_op(205);  break;
                              case 2:  set_op(220);  break;
                           }
                           set_op(op1_1);   set_op(op1_2);
                           if (mvflag > 0)  {  set_op(op2_2); }
                           if (mvflag > 1)  {  set_op(op3_2); }
                        } else if (err == 0) {
                           err = 7;
                        }
                        break;
                     case 1:
                        if (mvflag != 0) {
                           err = 7;
                        } else {
                           err = prebyte(id_1,0);
                           if ((err == 0)&&(id_2 <= 7)) {
                              set_op(160 + id_2); set_op(op1_1);
                           } else if (err == 0) {
                              err = 7;
                           }
                        }
                        break;
                     case 2:
                        err = prebyte(id_1,id_2);
                        if (err == 0) {
                           set_op(200 + mvflag); set_op(op1_1); set_op(op1_2);
                        }
                        break;
                     case 3:
                        if (err == 0) {
                           switch (id_2) {
                              case 0:
                                 err = prebyte(id_1,0);
                                 if (mvflag <= 3) {
                                    set_op(208 + mvflag);  set_op(op1_1);
                                    set_reg_opecode(4,op1_2,op2_2,op3_2);
                                 } else if (err == 0) {
                                    err = 7;
                                 }
                                 break;
                              case 1:  case 2:  case 3:
                                 err = prebyte(id_1,0);
                                 if ((mvflag <= 2)&&(op1_2 <= 7)) {
                                    set_op(224 + mvflag);
                                    set_mn_opecode(id_2,op1_2,op1_1,op2_2);
                                 }else if ((id_2!=1)&&(mvflag==3)&&(op1_2<=7)){
                                    set_op(86);
                                    set_mn_opecode(id_2,op1_2,op1_1,op2_2);
                                 } else if (err == 0) {
                                    err = 7;
                                 }
                                 break;
                              case 4:  case 5:
                                 err = prebyte(id_1,0);
                                 if ((mvflag <= 3)&&(op1_2 <= 7)) {
                                    set_op(224 + mvflag);
                                    set_mn_opecode(id_2,op1_2,op1_1,op2_2);
                                 } else if (err == 0) {
                                    err = 7;
                                 }
                                 break;
                              case 6:  case 7:  case 8:
                                 err = prebyte(id_1,op1_2);
                                 if (mvflag <= 3) {
                                    set_op(240 + mvflag);
                                    set_mn_opecode(id_2,op1_1,op2_2,op3_2);
                                 } else if (err == 0) {
                                    err = 7;
                                 }
                                 break;
                           }
                        }
                        break;
                  }
               } else if (gid_1 == 3) {
                  switch (id_1) {
                     case 0:
                        switch (gid_2) {
                           case 1:
                              if ((id_2 <= 7)&&(mvflag == 0)) {
                                 set_op(168 + id_2);
                                 set_reg_opecode(4,op1_1,op2_1,op3_1);
                              } else {
                                 err = 7;
                              }
                              break;
                           case 2:
                              err = prebyte(id_2,0);
                              if ((err == 0)&&(mvflag <= 3)) {
                                 set_op(216 + mvflag); set_op(op1_1);
                                 set_reg_opecode(4,op2_1,op3_1,op1_2);
                              } else if (err == 0) {
                                 err = 7;
                              }
                              break;
                           default:
                              err = 7;
                              break;
                        }
                        break;
                     case 1:  case 2:  case 3:  case 4:  case 5:
                        switch (gid_2) {
                           case 1:
                              if ((op1_1 <= 7)&&(id_2 <= 6)&&(mvflag == 0)) {
                                 set_op(176 + id_2);
                                 set_r3_opecode(id_1,op1_1,op2_1);
                              } else {
                                 err = 7;
                              }
                              break;
                           case 2:
                              err = prebyte(id_2,0);
                              if ((op1_1 <= 7)&&(err == 0)) {
                                 if ((mvflag <= 2)||
                                     ((mvflag == 3)&&((id_1==4)||(id_1==5)))) {
                                    set_op(232 + mvflag);
                                    set_mn_opecode(id_1,op1_1,op1_2,op2_1);
                                 } else if (((mvflag == 3)&&(id_1 >= 2))) {
                                    set_op(94);
                                    set_mn_opecode(id_1,op1_1,op1_2,op2_1);
                                 } else {
                                    err = 7;
                                 }
                              } else if (err == 0) {
                                 err = 7;
                              }
                              break;
                           default:
                              err = 7;
                              break;
                        }
                        break;
                     case 6:  case 7:  case 8:
                        switch (gid_2) {
                           case 1:
                              err = prebyte(op1_1,0);
                              if ((err == 0)&&(id_2 <= 6)&&(mvflag == 0))  {
                                 set_op(184 + id_2);
                                 set_r3_opecode(id_1,op2_1,op3_1);
                              } else if (err == 0) {
                                 err = 7;
                              }
                              break;
                           case 2:
                              err = prebyte(op1_1,id_2);
                              if ((err == 0)&&(mvflag <= 3)) {
                                 set_op(248 + mvflag);
/*                                 set_mn_opecode(id_1,op2_1,op3_1,op1_2);  Kako Makes a Big Mistake! */
                                   set_mn_opecode(id_1,op2_1,op1_2,op3_1);
                              } else if (err == 0) {
                                 err = 7;
                              }
                              break;
                           default:
                              err = 7;
                              break;
                        }
                        break;
                  }
               } else {
                  err = 7;
               }
            }
         } else {
            err = 8;
         }
      }
   } else {
      err = 8;
   }
   return err;
}
