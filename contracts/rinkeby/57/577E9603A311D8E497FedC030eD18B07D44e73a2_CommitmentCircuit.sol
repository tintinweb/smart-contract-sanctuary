// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SchnorrSignature.sol";

contract CommitmentCircuit is SchnorrSignature, Ownable {
	using SafeERC20 for IERC20;

	IERC20 public xftTokenAddress;

	// todo: public is temporary
	mapping(address => uint256[]) public _idsByAddress;
	mapping(uint256 => PointEC) public _commitmentById;
	mapping(uint256 => bool) public _spents; // spents[id]

	event CommitmentTransferred(
		address indexed sender,
		address indexed recipient,
		uint256 senderCommitmentId,
		uint256 recipientCommitmentId,
		PointEC senderCommitment,
		PointEC recipientCommitment
	);
	event Deposited(
		address indexed to,
		uint256 amount,
		uint256 indexed commitmentId,
		PointEC commitment
	);
	event Withdrawn(
		address indexed to,
		uint256 amount,
		uint256 indexed commitmentIdOld,
		PointEC commitmentOld
	);

	constructor(address _xftTokenAddress) {
		xftTokenAddress = IERC20(_xftTokenAddress);
	}
	
	function updateTokenAddress(address _newAddress) public onlyOwner() {
		require(_newAddress != address(0), "Zero address");
		xftTokenAddress = IERC20(_newAddress);
	}

	function transferCommitment(
		address recipient,
		uint256 senderCommitmentId,
		PointEC memory recipientCommitment,
		PointEC memory senderPubKey,
		PointEC memory recipientPubKey,
		string memory message,
		PointEC memory pubKey,
		PointEC memory ecR,
		uint256 s
	) public {
		require(SchnorrSignatureVerify(message, pubKey, ecR, s), "invalid signature");
		require(_spents[senderCommitmentId], "commitment already used");
		PointEC memory senderCommitment = _commitmentById[senderCommitmentId];
		PointEC memory _ecEqual;
		(_ecEqual.x, _ecEqual.y) = eSub(senderPubKey.x, senderPubKey.y, recipientPubKey.x, recipientPubKey.y);
		require(
			_CommitmentVerify(senderCommitment, recipientCommitment, _ecEqual),
			"invalid commitments"
		);

		_spents[senderCommitmentId] = false;
		uint256 id = _CommitmentNewAdd(recipient, recipientCommitment);
		emit CommitmentTransferred(
			msg.sender,
			recipient,
			senderCommitmentId,
			id,
			senderCommitment,
			_commitmentById[id]
		);
	}

	function deposit(
		uint256 amount,
		PointEC memory recipientCommitment,
		PointEC memory pubKey,
		PointEC memory ecR,
		uint256 s,
		string memory message
	) public {
		require(SchnorrSignatureVerify(message, pubKey, ecR, s), "invalid signature");

		xftTokenAddress.safeTransferFrom(msg.sender, address(this), amount);
		uint256 id = _CommitmentNewAdd(msg.sender, recipientCommitment);

		emit Deposited(msg.sender, amount, id, _commitmentById[id]);
	}

	function withdraw(
		uint256 amount,
		uint256 recipientCommitmentOldId,
		PointEC memory pubKey,
		PointEC memory ecR,
		string memory message,
		uint256 s
	) public {
		require(SchnorrSignatureVerify(message, pubKey, ecR, s), "invalid signature");
		require(_spents[recipientCommitmentOldId], "commitment already used");
		// PointEC memory comm;

		xftTokenAddress.safeTransfer(msg.sender, amount);
		_spents[recipientCommitmentOldId] = false;
		// uint256 id = _CommitmentNewAdd(msg.sender, recipientCommitment);

		emit Withdrawn(
			msg.sender,
			amount,
			recipientCommitmentOldId,
			// id,
			_commitmentById[recipientCommitmentOldId]
			// _commitmentById[id]
		);
	}

	function _CommitmentNewAdd(address _newOwner, PointEC memory _commitment)
		internal
		returns (uint256)
	{
		uint256 _id = _idsByAddress[_newOwner].length + 1;
		_commitmentById[_id] = _commitment;
		_idsByAddress[_newOwner].push(_id);
		_spents[_id] = true;
		return _id;
	}

	function _CommitmentVerify( 
		PointEC memory _ecCommInput,
		PointEC memory _ecCommOutput,
		PointEC memory _ecCommValid
	) internal pure returns (bool) {
		PointEC memory _ecP;
		(_ecP.x, _ecP.y) = eSub(_ecCommInput.x, _ecCommInput.y, _ecCommOutput.x, _ecCommOutput.y);
		return _equalPointEC(_ecP, _ecCommValid);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./RP/RangeProofMath.sol";

contract SchnorrSignature is RangeProofMath {

    function SchnorrSignatureVerify
    (
        string memory message, 
        PointEC memory publicKey,
        PointEC memory ecR,
        uint256 s
    ) 
    public pure returns (bool)
    {
        uint256 messageHash;
        PointEC memory ecG;
        PointEC memory ecLeft;
        PointEC memory ecRight;

        require(
            eIsOnCurve(publicKey.x, publicKey.y) && 
            eIsOnCurve(ecR.x, ecR.y),
            "Invalid input parametrs to verify the Schnorr signature"
        );

        // c = H (X, R, m)
        messageHash = uint256(sha256(abi.encodePacked(
            publicKey.x, publicKey.y,
            ecR.x, ecR.y,
            message        
        )));
        //s*G
        ecG.x = gx;
        ecG.y = gy;
        
        (ecLeft.x, ecLeft.y) = eMul(s, ecG.x, ecG.y);
        //R + c*X
        (ecRight.x, ecRight.y) = eMul(messageHash, publicKey.x, publicKey.y);
        (ecRight.x, ecRight.y) = eAdd(ecRight.x, ecRight.y, ecR.x, ecR.y);
        return _equalPointEC(ecLeft, ecRight);
        // return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "../EC/EllipticCurve.sol";

contract RangeProofMath is EllipticCurve {
    
    struct PointEC {
        uint256 x;
        uint256 y;
    }

    struct SlotCount {
        uint256 n;
        uint256 m; //count Vj
        uint256 k; //count L and R 
    }

    struct SlotChallenge {
        uint256 y;
        uint256 z;
        uint256 x;
        uint256 w;
        uint256 delta;
    }

    struct SlotRangeProof {
        PointEC[] arrVj;
        PointEC ecA; PointEC ecS; 
        PointEC ecT1; PointEC ecT2;
        uint256 utx; uint256 uttx; uint256 uee;
        PointEC[] arrLk; PointEC[] arrRk;
        uint256 ua; uint256 ub;
    }


    function _hashPPToChallange (PointEC memory _pEC_1, PointEC memory _pEC_2) internal pure returns (uint256) {
        return uint256( sha256(abi.encode(_pEC_1.x, _pEC_1.y, _pEC_2.x, _pEC_2.y)));
    }

    function _negMod (uint256 _v) internal pure returns (uint256 _negM) {
        _negM = mulmod(1, _v, nn);
        _negM = nn - _negM;
    }

    function _invMatrMod (uint256[] memory _arrMatr, uint256 _mod) internal pure returns (uint256[] memory _arrInvMatr) {
        _arrInvMatr = new uint256[](_arrMatr.length);
        for (uint8 i = 0; i < _arrMatr.length; i++){
            _arrInvMatr[i] = invMod(_arrMatr[i], _mod);
        }
    }

    function _genPointEC (bytes memory _paramSHA) 
    internal 
    pure 
    returns (PointEC memory _pEC)
    {
        uint256 _x;
        uint256 _y;
        uint8 _i;
        while (_i<256){
            _x = addmod(uint256(0), uint256(sha256(abi.encodePacked(_i, _paramSHA))), pp);
            _y = eDeriveY(2, _x);
            if (eIsOnCurve(_x, _y) == true) {
                _pEC.x = _x;
                _pEC.y = _y;
                return _pEC;
            }
            _i++;                
        }
    }

    function _genMatrixECPoints (bytes memory _paramSHA, uint256 _n) 
    internal 
    pure
    returns (PointEC[] memory _matrixECPoints) 
    {
        _matrixECPoints = new PointEC[](_n);
        for (uint8 i = 0; i < _n; i++){
            _matrixECPoints[i] = _genPointEC(abi.encodePacked(_paramSHA, i));
            if (_matrixECPoints[i].y < uint256(pp/2)) {_matrixECPoints[i].y = pp - _matrixECPoints[i].y;}
        }
    }

    function _equalPointEC
    (
        PointEC memory _pEC1, 
        PointEC memory _pEC2
    ) internal pure returns (bool _isEq)
    {
        _isEq = (_pEC1.x == _pEC2.x) && (_pEC1.y == _pEC2.y);
    }

    function _calc_matrix_u (uint256 _k, PointEC[] memory _arrLk, PointEC[] memory _arrRk) internal pure returns ( uint256[] memory _arrUk )
    {
        _arrUk = new uint256[](_k);
        for (uint8 i = 0; i < _k; i++){
            _arrUk[i] = mulmod(1,_hashPPToChallange(_arrLk[i], _arrRk[i]), nn);
        }
    }


    function _calc_delta ( SlotCount memory _count, SlotChallenge memory _challenge ) internal pure returns ( uint256 _delta )
    {

        uint256 _n = _count.n;
        uint256 _m = _count.m;

        uint256 _y = _challenge.y;
        uint256 _z = _challenge.z;

        uint256 _v1 = 1; //y^n
        uint256 _v2 = 1; //2^n

        uint256 _spm1 = 1; // <1, y^n>
        uint256 _spm2 = 1; // <1, 2^n>

        uint256 _zz = mulmod(_z, _z, nn); //z^2 mod k

        // _zz = addmod(_negMod(_zz), _z, nn); // z-z^2

        // (z-z^2) * <1, y ^ n*m> === (z-z^2)* m * <1, y^n>
        for (uint8 i = 1; i < _n; i++) {

            _v1 = mulmod(_v1, _y, nn);
            _spm1 = addmod(_spm1, _v1, nn); // <1, y^n>

            _v2 = mulmod(_v2, 2, nn);
            _spm2 = addmod(_spm2, _v2, nn); // <1, 2^n>
        }
        _delta = mulmod( mulmod(_spm1, _m, nn), addmod(_negMod(_zz), _z, nn), nn) ; // (z-z^2)* m * <1, y^n>

        // -z^3*summ(z^j)*<1, 2^nm> == -summ(z^j) * z^3 * m * <1, 2^n>
        
        _spm1 = 1;
        for (uint j = 1; j < _m; j++){
            _v1 = mulmod(_v1, _z, nn); //z^j
            _spm1 = addmod(_spm1, _v1, nn); // summ(z^j)
        }
        _spm1 = mulmod(mulmod(_zz, _z, nn), _spm1, nn);
        _spm1 = mulmod(_spm1, mulmod(_spm2, _m, nn), nn);
        
        _delta = addmod(_delta, _negMod(_spm1), nn);    
    }

    function _calcChallY(
        PointEC memory _ecA,
        PointEC memory _ecS
    ) internal pure returns (uint256 _chall) {
        require (eIsOnCurve(_ecA.x, _ecA.y), "Argument '_ecA' is not ec point");
        require (eIsOnCurve(_ecS.x, _ecS.y), "Argument '_ecS' is not ec point");
        _chall = addmod(0, _hashPPToChallange(_ecA, _ecS), nn);            
    }

    function _calcChallZ(
        PointEC memory _ecA,
        PointEC memory _ecS,
        uint256 _y
    ) internal pure returns (uint256 _chall) {
        _chall = addmod(0, uint256(sha256(abi.encode(_ecA.x, _ecA.y, _ecS.x, _ecS.y, _y) ) ), nn);
    }

    function _calcChallX(
        PointEC memory _ecT1,
        PointEC memory _ecT2
    ) internal pure returns (uint256 _chall) {
        require (eIsOnCurve(_ecT1.x, _ecT1.y), "Argument '_ecT1' is not ec point");
        require (eIsOnCurve(_ecT2.x, _ecT2.y), "Argument '_ecT2' is not ec point");
        _chall = addmod(0, _hashPPToChallange(_ecT1, _ecT2), nn);
    }

    function _calcChallW(
        uint256 _tx,
        uint256 _ttx,
        uint256 _ee
    ) internal pure returns (uint256 _chall) {
        _chall = addmod(0, uint256( sha256(abi.encode(_tx, _ttx, _ee))), nn);
    }

    function _calc_counters(
        PointEC[] memory _Vj,
        PointEC[] memory _Lk,
        PointEC[] memory _Rk
        ) internal pure returns ( SlotCount memory _count) {
        //m- number of participants
        _count.m = _Vj.length;
        require(_count.m > 0, "Array Vj is empty");

        _count.k = _Lk.length;
        require(_count.k > 0, "Arrays Lk and Rk with an error");
        require(_count.k == _Rk.length, "Rk and Lk have different sizes");

        //n- length 'v' in bits or k = log2(n) => n = 2^k
        _count.n = 2**_count.k;
    }

    function _gen_matrix_product (uint8 _n, uint256 _v, uint256 _mod) internal pure returns (uint256[] memory arrProd){
        arrProd = new uint256[](_n);
        arrProd[0] = 1;
        for (uint8 i = 1; i < _n; i++){
            arrProd[i] = mulmod(arrProd[i-1], _v, _mod);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

//Elliptic Curve Library
//Library providing arithmetic operations over elliptic curves.
//This library does not check whether the inserted points belong to the curve
//`isOnCurve` function should be used by the library user to check the aforementioned statement.
//@author Witnet Foundation
library EllipticCurveMath {

  // Pre-computed constant for 2 ** 255
  uint256 constant private 
    _U255_MAX_PLUS_1 = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  // Modular euclidean inverse of a number (mod p).
  // q such that x*q = 1 (mod _pp)
  function _invMod(uint256 _x, uint256 _pp) internal pure returns (uint256) {
    require(_x != 0 && _x != _pp && _pp != 0, "Invalid number");
    uint256 q = 0;
    uint256 newT = 1;
    uint256 r = _pp;
    uint256 t;
    while (_x != 0) {
      t = r / _x;
      (q, newT) = (newT, addmod(q, (_pp - mulmod(t, newT, _pp)), _pp));
      (r, _x) = (_x, r - t * _x);
    }

    return q;
  }

  /// Modular exponentiation, b^e % _pp.
  /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
  /// r such that r = b**e (mod _pp)
  function _expMod(
    uint256 _base, 
    uint256 _exp, 
    uint256 _pp) 
    internal pure returns (uint256) {
    require(_pp!=0, "Modulus is zero");

    if (_base == 0)
      return 0;
    if (_exp == 0)
      return 1;

    uint256 r = 1;
    uint256 bit = _U255_MAX_PLUS_1;
    assembly {
      for { } gt(bit, 0) { }{
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, bit)))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 2))))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 4))))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 8))))), _pp)
        bit := div(bit, 16)
      }
    }

    return r;
  }

  // Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1).
  // (x', y') affine coordinates
  function _toAffine(
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _pp)
    internal pure returns (uint256, uint256)
  {
    uint256 zInv = _invMod(_z, _pp);
    uint256 zInv2 = mulmod(zInv, zInv, _pp);
    uint256 x2 = mulmod(_x, zInv2, _pp);
    uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, _pp), _pp);

    return (x2, y2);
  }

  // Derives the y coordinate from a compressed-format point x [[SEC-1]](https://www.secg.org/SEC1-Ver-1.0.pdf).
  // _prefix parity byte (0x02 even, 0x03 odd)
  // return y coordinate y
  function _deriveY(
    uint8 _prefix,
    uint256 _x,
    uint256 _aa,
    uint256 _bb,
    uint256 _pp)
    internal pure returns (uint256)
  {
    require(_prefix == 0x02 || _prefix == 0x03, "Invalid compressed EC point prefix");
    // x^3 + ax + b
    uint256 y2 = addmod(mulmod(_x, mulmod(_x, _x, _pp), _pp), addmod(mulmod(_x, _aa, _pp), _bb, _pp), _pp);
    y2 = _expMod(y2, (_pp + 1) / 4, _pp);
    uint256 y = (y2 + _prefix) % 2 == 0 ? y2 : _pp - y2;
    return y;
  }

  // Check whether point (x,y) is on curve defined by a, b, and _pp.
  //return true if x,y in the curve, false else
  function _isOnCurve(
    uint _x,
    uint _y,
    uint _aa,
    uint _bb,
    uint _pp)
    internal pure returns (bool)
  {
    if (0 == _x || _x >= _pp || 0 == _y || _y >= _pp) {
      return false;
    }
    // y^2
    uint lhs = mulmod(_y, _y, _pp);
    // x^3
    uint rhs = mulmod(mulmod(_x, _x, _pp), _x, _pp);
    if (_aa != 0) {
      // x^3 + a*x
      rhs = addmod(rhs, mulmod(_x, _aa, _pp), _pp);
    }
    if (_bb != 0) {
      // x^3 + a*x + b
      rhs = addmod(rhs, _bb, _pp);
    }

    return lhs == rhs;
  }

  //Calculate inverse (x, -y) of point (x, y).
  //return (x, -y)
  function _ecInv(
    uint256 _x,
    uint256 _y,
    uint256 _pp)
    internal pure returns (uint256, uint256)
  {
    return (_x, (_pp - _y) % _pp);
  }

  // Add two points (x1, y1) and (x2, y2) in affine coordinates.
  // return (qx, qy) = P1+P2 in affine coordinates
  function _ecAdd(
    uint256 _x1,
    uint256 _y1,
    uint256 _x2,
    uint256 _y2,
    uint256 _aa,
    uint256 _pp)
    internal pure returns(uint256, uint256)
  {
    uint x = 0;
    uint y = 0;
    uint z = 0;

    if (_x1==_x2) {
      // y1 = -y2 mod p
      if (addmod(_y1, _y2, _pp) == 0) {
        return(0, 0);
      } else {
        // P1 = P2
        (x, y, z) = _jacDouble(
          _x1,
          _y1,
          1,
          _aa,
          _pp);
      }
    } else {
      (x, y, z) = _jacAdd(
        _x1,
        _y1,
        1,
        _x2,
        _y2,
        1,
        _pp);
    }
    // Get back to affine
    return _toAffine(
      x,
      y,
      z,
      _pp);
  }

  // Substract two points (x1, y1) and (x2, y2) in affine coordinates.
  // return (qx, qy) = P1-P2 in affine coordinates
  function _ecSub(
    uint256 _x1,
    uint256 _y1,
    uint256 _x2,
    uint256 _y2,
    uint256 _aa,
    uint256 _pp)
    internal pure returns(uint256, uint256)
  {
    // invert square
    (uint256 x, uint256 y) = _ecInv(_x2, _y2, _pp);
    // P1-square
    return _ecAdd(
      _x1,
      _y1,
      x,
      y,
      _aa,
      _pp);
  }

  // Multiply point (x1, y1, z1) times d in affine coordinates.
  // return (qx, qy) = d*P in affine coordinates
  function _ecMul(
    uint256 _k,
    uint256 _x,
    uint256 _y,
    uint256 _aa,
    uint256 _pp)
    internal pure returns(uint256, uint256)
  {
    // Jacobian multiplication
    (uint256 x1, uint256 y1, uint256 z1) = _jacMul(
      _k,
      _x,
      _y,
      1,
      _aa,
      _pp);
    // Get back to affine
    return _toAffine(
      x1,
      y1,
      z1,
      _pp);
  }

  // Adds two points (x1, y1, z1) and (x2 y2, z2).
  // return (qx, qy, qz) P1+square in Jacobian
  function _jacAdd(
    uint256 _x1,
    uint256 _y1,
    uint256 _z1,
    uint256 _x2,
    uint256 _y2,
    uint256 _z2,
    uint256 _pp)
    internal pure returns (uint256, uint256, uint256)
  {
    if (_x1==0 && _y1==0)
      return (_x2, _y2, _z2);
    if (_x2==0 && _y2==0)
      return (_x1, _y1, _z1);

    // We follow the equations described in 
    // https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
    uint[4] memory zs; // z1^2, z1^3, z2^2, z2^3
    zs[0] = mulmod(_z1, _z1, _pp);
    zs[1] = mulmod(_z1, zs[0], _pp);
    zs[2] = mulmod(_z2, _z2, _pp);
    zs[3] = mulmod(_z2, zs[2], _pp);

    // u1, s1, u2, s2
    zs = [
      mulmod(_x1, zs[2], _pp),
      mulmod(_y1, zs[3], _pp),
      mulmod(_x2, zs[0], _pp),
      mulmod(_y2, zs[1], _pp)
    ];

    // In case of zs[0] == zs[2] && zs[1] == zs[3], double function should be used
    require(zs[0] != zs[2] || zs[1] != zs[3], "Use jacDouble function instead");

    uint[4] memory hr;
    //h
    hr[0] = addmod(zs[2], _pp - zs[0], _pp);
    //r
    hr[1] = addmod(zs[3], _pp - zs[1], _pp);
    //h^2
    hr[2] = mulmod(hr[0], hr[0], _pp);
    // h^3
    hr[3] = mulmod(hr[2], hr[0], _pp);
    // qx = -h^3  -2u1h^2+r^2
    uint256 qx = addmod(mulmod(hr[1], hr[1], _pp), _pp - hr[3], _pp);
    qx = addmod(qx, _pp - mulmod(2, mulmod(zs[0], hr[2], _pp), _pp), _pp);
    // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
    uint256 qy = mulmod(hr[1], addmod(mulmod(zs[0], hr[2], _pp), _pp - qx, _pp), _pp);
    qy = addmod(qy, _pp - mulmod(zs[1], hr[3], _pp), _pp);
    // qz = h*z1*z2
    uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, _pp), _pp);
    return(qx, qy, qz);
  }

  // Doubles a points (x, y, z).
  // return (qx, qy, qz) 2P in Jacobian
  function _jacDouble(
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _aa,
    uint256 _pp)
    internal pure returns (uint256, uint256, uint256)
  {
    if (_z == 0)
      return (_x, _y, _z);

    // We follow the equations described in 
    // https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
    // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
    // x, y, z at this point represent the squares of _x, _y, _z
    uint256 x = mulmod(_x, _x, _pp); //x1^2
    uint256 y = mulmod(_y, _y, _pp); //y1^2
    uint256 z = mulmod(_z, _z, _pp); //z1^2

    // s
    uint s = mulmod(4, mulmod(_x, y, _pp), _pp);
    // m
    uint m = addmod(mulmod(3, x, _pp), mulmod(_aa, mulmod(z, z, _pp), _pp), _pp);

    // x, y, z at this point will be reassigned and rather represent qx, qy, qz from the paper
    // This allows to reduce the gas cost and stack footprint of the algorithm
    // qx
    x = addmod(mulmod(m, m, _pp), _pp - addmod(s, s, _pp), _pp);
    // qy = -8*y1^4 + M(S-T)
    y = addmod(mulmod(m, addmod(s, _pp - x, _pp), _pp), _pp - mulmod(8, mulmod(y, y, _pp), _pp), _pp);
    // qz = 2*y1*z1
    z = mulmod(2, mulmod(_y, _z, _pp), _pp);

    return (x, y, z);
  }

  // Multiply point (x, y, z) times d.
  // return (qx, qy, qz) d*P1 in Jacobian
  function _jacMul(
    uint256 _d,
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _aa,
    uint256 _pp)
    internal pure returns (uint256, uint256, uint256)
  {
    // Early return in case that `_d == 0`
    if (_d == 0) {
      return (_x, _y, _z);
    }

    uint256 remaining = _d;
    uint256 qx = 0;
    uint256 qy = 0;
    uint256 qz = 1;

    // Double and add algorithm
    while (remaining != 0) {
      if ((remaining & 1) != 0) {
        (qx, qy, qz) = _jacAdd(
          qx,
          qy,
          qz,
          _x,
          _y,
          _z,
          _pp);
      }
      remaining = remaining / 2;
      (_x, _y, _z) = _jacDouble(
        _x,
        _y,
        _z,
        _aa,
        _pp);
    }
    return (qx, qy, qz);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./EllipticCurveMath.sol";

contract EllipticCurve {
    uint256 public constant pp = uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F);
    uint256 public constant nn = uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141);
    uint256 public constant gx = uint256(0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798);
    uint256 public constant gy = uint256(0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8);
    uint256 public constant aa = uint256(0x0000000000000000000000000000000000000000000000000000000000000000);
    uint256 public constant bb = uint256 (0x0000000000000000000000000000000000000000000000000000000000000007);

    function eAdd ( uint256 _x1 , uint256 _y1 , uint256 _x2 , uint256 _y2 )
        public
        pure
        returns ( uint256 _x3 , uint256 _y3 )
    {
        (_x3,_y3) = EllipticCurveMath._ecAdd(_x1,_y1,_x2,_y2,0,pp);
    }

    function eSub( uint256 _x1 , uint256 _y1 , uint256 _x2 , uint256 _y2 )
        public
        pure
        returns ( uint256 _x3 , uint256 _y3 )
    {
        (_x3,_y3) = EllipticCurveMath._ecSub(_x1,_y1,_x2,_y2,0,pp);
    }

    function eMul( uint256 _z , uint256 _x1 , uint256 _y1 )
        public
        pure
        returns ( uint256 _x2 , uint256 _y2 )
    {
        (_x2,_y2) = EllipticCurveMath._ecMul(_z,_x1,_y1,0,pp);
    }

    function eDeriveY ( uint8 _prefix, uint256 _x)
        public
        pure
        returns (uint256 _y)
    {
        _y = EllipticCurveMath._deriveY (_prefix, _x, aa, bb, pp);
    }

    function eIsOnCurve (uint256 _x, uint256 _y)
        public
        pure
        returns(bool _is)
    { 
        _is = EllipticCurveMath._isOnCurve(_x, _y, aa, bb, pp); 
    }

    function invMod(uint256 _x, uint256 _pp) 
        public 
        pure 
        returns (uint256 _g) {
            _g = EllipticCurveMath._invMod(_x, _pp);
        }

    function expMod (uint256 _base, uint256 _exp, uint256 _pp) 
        public 
        pure 
        returns (uint256 _r) {
            _r = EllipticCurveMath._expMod(_base, _exp, _pp);
    }

    function eInv (uint256 _x1, uint256 _y1) 
        public 
        pure 
        returns (uint256 _x2 , uint256 _y2) {
            (_x2, _y2) = EllipticCurveMath._ecInv (_x1, _y1, pp);
    }

// obtain Pederson Commitment with no fixed points x*G + r*H
    function ePedersenCommitment( 
        uint256 _x , uint256 _r,
        uint256 _gx , uint256 _gy,
        uint256 _hx , uint256 _hy
    )        
        public
        pure
        returns ( uint256 _x3 , uint256 _y3 )
    {
        ( uint256 _x1 , uint256  _y1 ) = eMul( _x , _gx , _gy );
        ( uint256 _x2 , uint256 _y2 ) = eMul(_r , _hx , _hy );
        ( _x3 , _y3 ) = eAdd( _x1 , _y1 , _x2 , _y2 );
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}