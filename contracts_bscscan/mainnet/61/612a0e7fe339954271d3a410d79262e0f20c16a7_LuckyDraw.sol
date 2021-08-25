/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract Context {
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
interface NFT {
    function mint(address to,string memory image, uint _type, string memory _name, string memory _description) external returns (uint256);
    function mints(address to,string memory image, uint _type, string memory _name, string memory _description, uint _time) external;
    function burn(uint256 tokenId) external;
    function metadatas(uint _tokenId) external view returns(string memory image, uint _type);
}
interface LuckyDrawV1 {
    function bigJackpot() external view returns(uint);
    function getTop10Winner() external view returns(address[]memory);
    function getTop10Player() external view returns(address[] memory);
    function users(address) external view returns(uint totalSpin, uint totalWin, uint claimJackbot, bool top10Winner, bool top10Player);
}
contract LuckyDraw is Ownable{
    using SafeMath for uint256;
    IBEP20 public GOUDA;
    LuckyDrawV1 luckyDrawV1 = LuckyDrawV1(0x47CCde84023bf697Dd2248eafF86a8768a74679B);
    struct percent {
        uint percent;
        string nftImage;
        string name;
    }
    mapping(uint => percent) public percents;
    uint[] public percentArr = [0,5,10,50,100,500];
    address public burn = 0x000000000000000000000000000000000000dEaD;
    NFT public nft = NFT(0x66EBfDB905fbCB0bc1E99E411a3f2E8366B5e60a);
    
    uint public jackpotAmount = 100000 ether;
    uint public jackpotPrize = 10000 ether;
    uint public nonce;
    bool public stop;
    uint public bigJackpot = luckyDrawV1.bigJackpot();
    address[] public top10Winner;
    address[] public top10Player;
    address[] public winnerBigJacpot;
    uint public indexTop10Winner;
    uint public indexTop10Player;
    struct user {
        uint totalSpin;
        uint totalWin;
        uint claimJackbot;
        bool top10Winner;
        bool top10Player;
    }
    mapping(address => user) public users;
    string public magicImg = 'QmSHCroNN7AGt2b1PLmV2SnuNzWLnU3ifMdFTeLdE7A41R';
    constructor () public {
        percents[0] = percent(9990, 'QmXkigsG9o9PsPMnCJrdKcVYLuEjQH2hJKzeYu56wnsern', 'Titan Bull'); // big jackpot 
        percents[5] = percent(800, 'QmUF1bCHA88NZNskkArL24tnDihHfFGURoq9Dzfg5Xeu95', 'Lucky Cow');
        percents[10] = percent(850, 'QmVCSUAZy1429TBhPJXaMBcyL9AcPwX19iB6egpp84zzqx', 'Catoblepas');
        percents[50] = percent(970, 'QmfA2u9sk9usYcZm9n4NYAUTtPwgC3CwNSiZcqWTAv8Dzz', 'Cretan');
        percents[100] = percent(990, 'QmVtH6b13wQL7cDGnFYZUcwXwA1qQXFRUCiHL37V3oyWAt', 'Soul Taurus');
        percents[500] = percent(995, 'QmWtGSm8NeoFaBFVXTZC1TuzSgLk835qB9BdCc3cmwqrge', 'Golden Taurus');

        GOUDA = IBEP20(0x14B06bF2C5B0AFd259c47c4be39cB9368ef0be3f);
        top10Winner = luckyDrawV1.getTop10Winner();
        top10Player = luckyDrawV1.getTop10Player();
        for(uint i = 0; i < top10Player.length; i++) {
            uint _totalSpin;
            uint _totalWin;
            uint _claimJackbot;
            bool _top10Winner;
            bool _top10Player;
            (_totalSpin, _totalWin, _claimJackbot, _top10Winner, _top10Player) = luckyDrawV1.users(top10Player[i]);
            users[top10Player[i]] = user(_totalSpin, _totalWin, _claimJackbot, _top10Winner, _top10Player);
        }
    }
    function getTop10Winner() public view returns(address[]memory) {
        return top10Winner;
    }
    function getTop10Player() public view returns(address[] memory) {
        return top10Player;
    }
    function resetIndexWinner() internal {
        uint smallest = users[top10Winner[indexTop10Winner]].totalWin;
        for(uint i = 0; i < 10; i++) {
            if(smallest > users[top10Winner[i]].totalWin) {
                smallest = users[top10Winner[i]].totalWin;
                indexTop10Winner = i;
            }
        }
    }
    function resetIndexPlayer() internal {
        uint smallest = users[top10Player[indexTop10Player]].totalSpin;
        for(uint i = 0; i < 10; i++) {
            if(smallest > users[top10Player[i]].totalSpin) {
                smallest = users[top10Player[i]].totalSpin;
                indexTop10Player = i;
            }
        }
    }
    function setTop10Winner() internal {
        if(!users[msg.sender].top10Winner) {
            if(top10Winner.length < 10) {
                top10Winner.push(msg.sender); 
                users[msg.sender].top10Winner = true;
            } else {
                users[top10Winner[indexTop10Winner]].top10Winner = false;
                top10Winner[indexTop10Winner] = msg.sender;
                users[msg.sender].top10Winner = true;
                resetIndexWinner();
            }
        }
    }
    function setTop10Player() internal {
        if(!users[msg.sender].top10Player) {
            if(top10Player.length < 10) {
                top10Player.push(msg.sender); 
                users[msg.sender].top10Player = true;
            } else {
                users[top10Player[indexTop10Player]].top10Player = false;
                top10Winner[indexTop10Player] = msg.sender;
                users[msg.sender].top10Player = true;
                resetIndexPlayer();
            }
        }
    }
    function claimJackbot() public {
        require(users[msg.sender].totalSpin.sub(users[msg.sender].claimJackbot) > jackpotAmount, 'User not meet condition !');
        GOUDA.transfer(msg.sender, jackpotPrize);
        users[msg.sender].claimJackbot += jackpotAmount;
    }
    function getUser(address _user) public view returns(user memory) {
        return users[_user];
    }
    function config(uint _jackpotAmount, uint _jackpotPrize, NFT _nft) public onlyOwner {
        jackpotAmount = _jackpotAmount;
        jackpotPrize = _jackpotPrize;
        nft = _nft;
    }
    function configPercent(uint _type, uint _p, string memory _image, string memory _name) public onlyOwner {
        if(percents[_type].percent == 0) percentArr[percentArr.length] = _type;
        percents[_type] = percent(_p, _image, _name);
    }
    function configMagicImg(string memory _magicImg) public onlyOwner {
        magicImg = _magicImg;
    }
    function toggleStop() public onlyOwner {
        stop = !stop;
    }
    function _burnProfit(uint amount) internal {
        GOUDA.transfer(burn, amount.mul(50).div(100));
        bigJackpot += amount.mul(20).div(100);
    }
    function _takeAsset(uint _type, uint _time) internal {
        uint amount;
        if(_type == 500) amount = 4 ether;
        else if(_type == 100) amount = 2 ether;
        else amount = 1 ether;
        amount = amount.mul(_time);
        require(GOUDA.transferFrom(msg.sender, address(this), amount), 'Address: insufficient balance');
        users[msg.sender].totalSpin += amount;
    }
    function _takeAsset(uint _time) internal {
        uint amount = 5 ether;
        amount = amount.mul(_time);
        require(GOUDA.transferFrom(msg.sender, address(this), amount), 'Address: insufficient balance');
        GOUDA.transfer(burn, amount.mul(50).div(100));
        bigJackpot += amount.mul(20).div(100);
        users[msg.sender].totalSpin += amount;
    }
    function exchangeNFT(uint[] memory tokenIds, uint _typeIndexTo) public {
        
        require(_typeIndexTo < percentArr.length, 'invalid type');
        uint multi = 3;
        if(_typeIndexTo == 3 || _typeIndexTo == 5) multi = 7;
        require(tokenIds.length % multi == 0, 'num NFT invalid');
        uint typeIndexFrom = _typeIndexTo == 0 ? 500 : percentArr[_typeIndexTo-1];
        for(uint i = 0; i < tokenIds.length; i++) {
            uint _type; 
            (, _type) = nft.metadatas(tokenIds[i]);
            require(_type == typeIndexFrom, 'invalid NFT');
            nft.burn(tokenIds[i]);
        }
        for(uint j = 0; j < tokenIds.length / multi; j++) {
            nft.mint(msg.sender, percents[_typeIndexTo].nftImage, percentArr[_typeIndexTo], percents[_typeIndexTo].name, 'Congratulations to the winner!');
        }
    }
    
    function claimBigJackpot(uint nftId) public {
        nft.burn(nftId);
        GOUDA.transfer(msg.sender, bigJackpot);
        bigJackpot = jackpotPrize;
    }
    function _markTheTest(bool _win, uint _type) internal {
        if(_win) {
            if(_type != 0) {
                uint winAmount = _type.mul(1 ether);
                users[msg.sender].totalWin += _type.mul(1 ether);
                GOUDA.transfer(msg.sender, winAmount);
                setTop10Winner();
            } else winnerBigJacpot.push(msg.sender);
            nft.mint(msg.sender, percents[_type].nftImage, _type, percents[_type].name, 'Congratulations to the winner!');
        }
        nonce += 1;
        setTop10Player();
    }
    function _random(uint _type) internal {
        require(!stop, 'not now');
        require(percents[_type].percent > 0, 'invalid prize');
        uint result = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % block.number;
        uint number = _type != 0 ? 999 : 9999;
        bool _win = result % number > percents[_type].percent;
        _markTheTest(_win, _type);
    }
    function random(uint _type) public {
        _takeAsset(_type, 1);
        _random(_type);
    }
    function randoms(uint _type, uint _time) public {
        require(_time <= 200, 'not now');
        uint before =GOUDA.balanceOf(address(this));
        _takeAsset(_type, _time);
        
        for(uint i = 0; i < _time; i++) {
            _random(_type);
        }
        uint afterRun = GOUDA.balanceOf(address(this));
        if(afterRun > before) _burnProfit(afterRun.sub(before));
    }
    function spinBigJackpotByMagicNFT(uint _tokenId) public {
        uint _type; 
        (, _type) = nft.metadatas(_tokenId);
        require(_type == 1, 'invalid tokenId');
        for(uint i = 0; i < 10; i++) {
            _random(0);
        }
        nft.burn(_tokenId);
    }
    function _random() internal {
        require(!stop, 'not now');
        uint result = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % block.number;
        uint number = 9999;
        bool _win;
        uint _type;
        for(uint i = 0; i < percentArr.length; i++) {
            _win = result % number > percents[percentArr[i]].percent;
            if(_win) {
                _type = percentArr[i];
                break;
            }
            
        }
        
        _markTheTest(_win, _type);
    }
    function random() public {
        _takeAsset(1);
        _random();
    }
    function randoms(uint _time) public {
        require(_time <= 200, 'not now');
        _takeAsset(_time);
        for(uint i = 0; i < _time; i++) {
            _random();
        }
    }
    
    function givewayMagicNFT(address[] memory _tos) public onlyOwner {
        for(uint i = 0; i < _tos.length; i++) {
            nft.mint(_tos[i], magicImg, 1, 'Magic Cow', 'Welcome to the world of Magic Cows!');
        }
    }
    function withdraw(IBEP20 _token, address _address, uint _amount) public onlyOwner {
        _token.transfer(_address, _amount);
    }
    function getRemainingToken(IBEP20 _token) public view returns (uint256) {
        return _token.balanceOf(address(this));
    }
}