/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Admin {
    using SafeMath for uint;
    
    event CEOTransfer(address newCEO, address oldCEO);

    address payable public CEOAddress;
    
    modifier onlyCEO() {
        require(msg.sender == CEOAddress);
        _;
    }
  
    function setCEO(address payable _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        emit CEOTransfer(_newCEO, CEOAddress);
        CEOAddress = _newCEO;
    }

    function withdrawBalance() external onlyCEO {
        CEOAddress.transfer(address(this).balance);
    }

    function kill() public onlyCEO {
        //To Do
        selfdestruct(CEOAddress);
    }
}

contract Random is Admin{
    uint radex = 66;
    
    function _random (uint range, uint time, bytes32 data) internal view returns (uint) {
        uint key = uint(keccak256(abi.encodePacked(blockhash(block.number), radex, uint(21), time, data)));
        return key%range;
    }
    
    function _radex(address player, uint time) internal returns (uint) {
        if(radex > 256) {
            radex = radex/(_random(uint(keccak256(abi.encodePacked(time, player)))%radex, time, "radex"));
        } else {
            radex = radex + uint(blockhash(block.number - radex))%radex;
        }
    } 
    
    function random(uint range, string memory data) internal returns (uint) {
        _radex(msg.sender, uint(now));
        bytes32 hash = keccak256(abi.encodePacked(data));
        return _random(range, uint(now), hash);
    }
}

contract NFTTest is Random {
    event NFTGenerated(uint indexed _nft, uint[4] indexed _ids, uint[4] indexed _rates);
    
    uint[] heads;
    uint[] bodies;
    uint[] limbs;
    uint[] weapons;
    
    struct NFT {
        uint head;
        uint body;
        uint limb;
        uint weapon;
    }
    
    NFT[] NFTs;
    
    mapping (uint => uint) public headToHashrate;
    mapping (uint => uint) public bodyToHashrate;
    mapping (uint => uint) public limbToHashrate;
    mapping (uint => uint) public weaponToHashrate;
    
    mapping (uint => address) NFTtoOwner;
    mapping (uint => uint[4]) NFTtoHashrate;
    
    constructor () public {
        for(uint i=0; i<100; i++) {
            heads.push(i);
        }
        bodies = heads;
        limbs = heads;
        weapons = heads;
        CEOAddress = msg.sender;
    }
    
    function _deleteElement(uint[4] memory _ids) internal returns(bool) {
        heads[_ids[0]] = heads[heads.length-1];
        heads.pop();
        bodies[_ids[1]] = bodies[bodies.length-1];
        bodies.pop();
        limbs[_ids[2]] = limbs[limbs.length-1];
        limbs.pop();
        weapons[_ids[3]] = weapons[weapons.length-1];
        weapons.pop();
    }
    
    function _calculateHashrate(uint _index, string memory _data) internal returns(uint) {
        uint rate;
        if (_index <= 10) {
            rate = 800 + random(200, _data);
            rate = rate.add((10-_index).mul(20));
        } else if (_index > 10 && _index <= 50) {
            rate = 200 + random(300, _data);
            rate = rate.add((50-_index).mul(5));
        } else if (_index > 50 && _index <= 100) {
            rate = random(200, _data);
            rate = rate.add((100-_index));
        }
        return rate;
    }
    
    function buyNFT() payable public returns(uint) {
        require(msg.value >= 1 ether);
        uint headId = random(heads.length, "HEAD");
        uint bodyId = random(bodies.length, "BODY");
        uint limbId = random(limbs.length, "LIMB");
        uint weaponId = random(weapons.length, "WEAPON");
        uint[4] memory ids = [headId, bodyId, limbId, weaponId];
        _deleteElement(ids);
        
        uint headrate = _calculateHashrate(headId, "HEADRATE");
        require(headToHashrate[headId] == 0, "Head Element Repeated");
        headToHashrate[headId] = headrate;
        uint bodyrate = _calculateHashrate(bodyId, "BODYRATE");
        require(bodyToHashrate[bodyId] == 0, "Body Element Repeated");
        bodyToHashrate[bodyId] = bodyrate;
        uint limbrate = _calculateHashrate(limbId, "LIMBRATE");
        require(limbToHashrate[limbId] == 0, "Limb Element Repeated");
        limbToHashrate[limbId] = limbrate;
        uint weaponrate = _calculateHashrate(weaponId, "WEAPONRATE");
        require(weaponToHashrate[weaponId] == 0, "Weapon Element Repeated");
        weaponToHashrate[weaponId] = weaponrate;
        uint[4] memory rates = [headrate, bodyrate, limbrate, weaponrate];
        
        NFT memory _NFT = NFT({
           head: headId,
           body: bodyId,
           limb: limbId,
           weapon: weaponId
        });
        NFTs.push(_NFT);
        uint nftId = NFTs.length - 1;
        NFTtoOwner[nftId] = msg.sender;
        NFTtoHashrate[nftId] = rates;
        
        emit NFTGenerated(nftId, ids, rates);
    }
    
    function getNFT(uint nftId) public view returns(
        uint headId,
        uint headrate,
        uint bodyId,
        uint bodyrate,
        uint limbId,
        uint limbrate,
        uint weaponId,
        uint weaponrate
    ){
        NFT memory _NFT = NFTs[nftId];
        headId = _NFT.head;
        bodyId = _NFT.body;
        limbId = _NFT.limb;
        weaponId = _NFT.weapon;
        headrate = headToHashrate[headId];
        bodyrate = bodyToHashrate[bodyId];
        limbrate = limbToHashrate[limbId];
        weaponrate = weaponToHashrate[weaponId];
    }
    
    function getNFTOwner(uint nftId) public view returns(address) {
        return NFTtoOwner[nftId];
    }
    
    function NFTleft() public view returns(uint) {
        return heads.length;
    }
}