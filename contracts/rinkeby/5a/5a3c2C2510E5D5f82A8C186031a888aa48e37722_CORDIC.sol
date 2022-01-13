/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CORDIC
{
    int var1;

        function set(int x) public
    {
        var1 = x;
    }

    int32[20] public a = [int32(7854), 3927, 1963, 982, 491, 245, 123, 61, 31, 15, 8, 4, 2, 1, 0, 0, 0, 0, 0, 0];

    int32[20] public sin = [int32(7071), 3827, 1951, 980, 491, 245, 123, 61, 31, 15, 8, 4, 2, 1, 0, 0, 0, 0, 0, 0];
        
    int32[20] public cos = [int32(7071), 9239, 9808, 9952, 9988, 9997, 9999, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000];


    function arctan(int32 input) public view returns(int32)
    {
        int32 x = 10000;
        int32 xnew = 10000;
        int32 y = input;
        int32 ynew = input;
        int32 ang = 0;

        uint8 i = 0;
        for (i = 0; i <= 19; i = i + 1)
        {
            if (y > 0)
            {
                xnew = (x*cos[i] + y*sin[i]) / 10000;
                ynew = (y*cos[i] - x*sin[i]) / 10000;
                ang = ang + a[i];
            }

            else
            {
                xnew = (x*cos[i] - y*sin[i]) / 10000;
                ynew = (y*cos[i] + x*sin[i]) / 10000;
                ang = ang - a[i];
            }

            x = xnew;
            y = ynew;
        }
        return(ang);
    }

    function arcsin(int32 input) public view returns(int32)
    {
        int32 x = 10000;
        int32 xnew = 10000;
        int32 y = 0;
        int32 ynew = 0;
        int32 ang = 0;

        uint8 i = 0;
        for (i = 0; i <= 19; i = i + 1)
        {
            if (y < input)
            {
                xnew = (x*cos[i] - y*sin[i]) / 10000;
                ynew = (y*cos[i] + x*sin[i]) / 10000;
                ang = ang + a[i];
            }

            else
            {
                xnew = (x*cos[i] + y*sin[i]) / 10000;
                ynew = (y*cos[i] - x*sin[i]) / 10000;
                ang = ang - a[i];
            }

            x = xnew;
            y = ynew;
        }
        return(ang);
    }

    function arccos(int32 input) public view returns(int32)
    {
        int32 x = 10000;
        int32 xnew = 10000;
        int32 y = 0;
        int32 ynew = 0;
        int32 ang = 0;

        uint8 i = 0;
        for (i = 0; i <= 19; i = i + 1)
        {
            if (x < input)
            {
                xnew = (x*cos[i] - y*sin[i]) / 10000;
                ynew = (y*cos[i] + x*sin[i]) / 10000;
                ang = ang - a[i];
            }

            else
            {
                xnew = (x*cos[i] + y*sin[i]) / 10000;
                ynew = (y*cos[i] - x*sin[i]) / 10000;
                ang = ang + a[i];
            }

            x = xnew;
            y = ynew;
        }
        return(ang);
    }

    function fsin(int32 input) public view returns(int32)
    {
        int32 x = 10000;
        int32 xnew = 10000;
        int32 y = 0;
        int32 ynew = 0;
        int32 ang = 0;

        uint8 i = 0;
        for (i = 0; i <= 19; i = i + 1)
        {
            if (ang < input)
            {
                xnew = (x*cos[i] - y*sin[i]) / 10000;
                ynew = (y*cos[i] + x*sin[i]) / 10000;
                ang = ang + a[i];
            }

            else
            {
                xnew = (x*cos[i] + y*sin[i]) / 10000;
                ynew = (y*cos[i] - x*sin[i]) / 10000;
                ang = ang - a[i];
            }

            x = xnew;
            y = ynew;
        }
        return(y);
    }

    function fcos(int32 input) public view returns(int32)
    {
        int32 x = 10000;
        int32 xnew = 10000;
        int32 y = 0;
        int32 ynew = 0;
        int32 ang = 0;

        uint8 i = 0;
        for (i = 0; i <= 19; i = i + 1)
        {
            if (ang < input)
            {
                xnew = (x*cos[i] - y*sin[i]) / 10000;
                ynew = (y*cos[i] + x*sin[i]) / 10000;
                ang = ang + a[i];
            }

            else
            {
                xnew = (x*cos[i] + y*sin[i]) / 10000;
                ynew = (y*cos[i] - x*sin[i]) / 10000;
                ang = ang - a[i];
            }

            x = xnew;
            y = ynew;
        }
        return(x);
    }

    function ftan(int32 input) public view returns(int32)
    {
        int32 x = 10000;
        int32 xnew = 10000;
        int32 y = 0;
        int32 ynew = 0;
        int32 ang = 0;

        uint8 i = 0;
        for (i = 0; i <= 19; i = i + 1)
        {
            if (ang < input)
            {
                xnew = (x*cos[i] - y*sin[i]) / 10000;
                ynew = (y*cos[i] + x*sin[i]) / 10000;
                ang = ang + a[i];
            }

            else
            {
                xnew = (x*cos[i] + y*sin[i]) / 10000;
                ynew = (y*cos[i] - x*sin[i]) / 10000;
                ang = ang - a[i];
            }

            x = xnew;
            y = ynew;
        }
        //now divide y and x
        int32 res; res = 0;
        int32 digit;
        int8 j;

        j = 1;
        while(j <= 4)
        {
            digit = y / x;
            res = res + digit;
            res = res * 10;
            y = (y % x)*10;
            j = j + 1;
        }

        return(res);
    }
}