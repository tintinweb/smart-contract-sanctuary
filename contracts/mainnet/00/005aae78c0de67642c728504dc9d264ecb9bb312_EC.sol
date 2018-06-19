pragma solidity ^0.4.2;

contract EC {

    uint256 constant public gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 constant public gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 constant public n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 constant public a = 0;
    uint256 constant public b = 7;
    uint256[] public gxs;
    uint256[] public gys;
    uint256[] public gzs;

    function EC() public
    {
        gxs.push(gx);
        gys.push(gy);
        gzs.push(1);
    }
    
    function prepare(uint count) public
    {
        require(gxs.length < 256);
        uint256 x = gxs[gxs.length - 1];
        uint256 y = gys[gys.length - 1];
        uint256 z = gzs[gzs.length - 1];
        for (uint j = 0; j < count && gxs.length < 256; j++) {
            (x,y,z) = _ecDouble(x,y,z);
            gxs.push(x);
            gys.push(y);
            gzs.push(z);
        }
    }

    function _jAdd( uint256 x1,uint256 z1,
                    uint256 x2,uint256 z2) public pure
        returns(uint256 x3,uint256 z3)
    {
        (x3, z3) = (  addmod( mulmod(z2, x1 , n) ,
                              mulmod(x2, z1 , n),
                              n),
                      mulmod(z1, z2 , n)
                    );
    }

    function _jSub( uint256 x1,uint256 z1,
                    uint256 x2,uint256 z2) public pure
        returns(uint256 x3,uint256 z3)
    {
        (x3, z3) = (  addmod( mulmod(z2, x1, n),
                              mulmod(n - x2, z1, n),
                              n),
                      mulmod(z1, z2 , n)
                    );
    }

    function _jMul( uint256 x1,uint256 z1,
                    uint256 x2,uint256 z2) public pure
        returns(uint256 x3,uint256 z3)
    {
        (x3, z3) = (  mulmod(x1, x2 , n), mulmod(z1, z2 , n));
    }

    function _jDiv( uint256 x1,uint256 z1,
                    uint256 x2,uint256 z2) public pure
        returns(uint256 x3,uint256 z3)
    {
        (x3, z3) = (  mulmod(x1, z2 , n), mulmod(z1 , x2 , n));
    }

    function _inverse( uint256 val) public pure
        returns(uint256 invVal)
    {
        uint256 t=0;
        uint256 newT=1;
        uint256 r=n;
        uint256 newR=val;
        uint256 q;
        while (newR != 0) {
            q = r / newR;

            (t, newT) = (newT, addmod(t , (n - mulmod(q, newT,n)) , n));
            (r, newR) = (newR, r - q * newR );
        }

        return t;
    }


    function _ecAdd( uint256 x1,uint256 y1,uint256 z1,
                    uint256 x2,uint256 y2,uint256 z2) public pure
        returns(uint256 x3,uint256 y3,uint256 z3)
    {
        uint256 l;
        uint256 lz;
        uint256 da;
        uint256 db;

        if ((x1==0)&&(y1==0)) {
            return (x2,y2,z2);
        }

        if ((x2==0)&&(y2==0)) {
            return (x1,y1,z1);
        }

        if ((x1==x2)&&(y1==y2)) {
            (l,lz) = _jMul(x1, z1, x1, z1);
            (l,lz) = _jMul(l, lz, 3, 1);
            (l,lz) = _jAdd(l, lz, a, 1);

            (da,db) = _jMul(y1, z1, 2, 1);
        } else {
            (l,lz) = _jSub(y2, z2, y1, z1);
            (da,db)  = _jSub(x2, z2, x1, z1);
        }

        (l, lz) = _jDiv(l, lz, da, db);


        (x3, da) = _jMul(l, lz, l, lz);
        (x3, da) = _jSub(x3, da, x1, z1);
        (x3, da) = _jSub(x3, da, x2, z2);

        (y3, db) = _jSub(x1, z1, x3, da);
        (y3, db) = _jMul(y3, db, l, lz );
        (y3, db) = _jSub(y3, db, y1, z1 );


        if (da != db) {
            x3 = mulmod(x3, db, n);
            y3 = mulmod(y3, da, n);
            z3 = mulmod(da, db, n);
        } else {
            z3 = da;
        }

    }

    function _ecDouble(uint256 x1,uint256 y1,uint256 z1) public pure
        returns(uint256 x3,uint256 y3,uint256 z3)
    {
        (x3,y3,z3) = _ecAdd(x1,y1,z1,x1,y1,z1);
    }



    function _ecMul(uint256 d, uint256 x1,uint256 y1,uint256 z1) public pure
        returns(uint256 x3,uint256 y3,uint256 z3)
    {
        uint256 remaining = d;
        uint256 px = x1;
        uint256 py = y1;
        uint256 pz = z1;
        uint256 acx = 0;
        uint256 acy = 0;
        uint256 acz = 1;

        if (d==0) {
            return (0,0,1);
        }

        while (remaining != 0) {
            if ((remaining & 1) != 0) {
                (acx,acy,acz) = _ecAdd(acx,acy,acz, px,py,pz);
            }
            remaining = remaining / 2;
            (px,py,pz) = _ecDouble(px,py,pz);
        }

        (x3,y3,z3) = (acx,acy,acz);
    }

    function publicKey(uint256 privKey) public constant
        returns(uint256 qx, uint256 qy)
    {
        uint256 acx = 0;
        uint256 acy = 0;
        uint256 acz = 1;

        if (privKey == 0) {
            return (0,0);
        }

        for (uint i = 0; i < 256; i++) {
            if (((privKey >> i) & 1) != 0) {
                (acx,acy,acz) = _ecAdd(acx,acy,acz, gxs[i],gys[i],gzs[i]);
            }
        }
        
        acz = _inverse(acz);
        (qx,qy) = (mulmod(acx,acz,n),mulmod(acy,acz,n));
    }

    function deriveKey(uint256 privKey, uint256 pubX, uint256 pubY) public pure
        returns(uint256 qx, uint256 qy)
    {
        uint256 x;
        uint256 y;
        uint256 z;
        (x,y,z) = _ecMul(privKey, pubX, pubY, 1);
        z = _inverse(z);
        qx = mulmod(x , z ,n);
        qy = mulmod(y , z ,n);
    }

}