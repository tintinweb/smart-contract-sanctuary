/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function mint(address account, uint amount) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

contract Box{
    using SafeMath for uint256;

    uint256 public currentId = 0;
    uint256 public nonce;

    IERC20 public hope = IERC20(0xb080FC1d0b69BED3e7b69974209CFf24129776b4);
   
    address public wallet = 0x2a4279A5CEB495a064d49E6De59AD00B4dBD8228;


    struct BoxInfo{
        bool status;
        uint256 price;
        uint256 boxAmount;
        uint256 minHopeAmount;
        uint256 maxHopeAmount;
        uint256 bnbAmount;       
        uint256 starSaleTime;       
        uint256 sellBoxAmount;
        uint256 maxTotalbnb;
        uint256 sellbnb;
        uint256 sellHope;

    }
    mapping(uint256 => BoxInfo) public boxMap;


    mapping(address => bool) public manager;
    
    mapping(address => bool) public whitelist;

    event Plan(address user, uint256 hopeAmount, uint256 bnbAmount);

    constructor() public {
        manager[msg.sender] = true;
        _setBoxMap(0, true, 3000, 1 * 10 ** 17, 757875000 * 10 **18, 757875000 * 10 ** 18 * 2 /10, 5 * 10 ** 16, 10 * 10 **17 , block.timestamp);
		_setWhitelist(0x2d008b4192aC5f33D996f47f7ae2497d75299a67,true);
		_setWhitelist(0x20cc39B92243C51b928c1a950dFc5885Ee16a25B,true);
		_setWhitelist(0xEf2d4F51854B20CF9C6437bA543cB6Bb5C4B78eD,true);
		_setWhitelist(0x70E41ECE1c5D5D1e5c5e26AB877792a0aF76C7be,true);
		_setWhitelist(0x08c76B7Fafa9991470432dA5cbDB5E51c68a409e,true);
		_setWhitelist(0xC56049325160d701Ee293FBeFd7e8C325ac4D409,true);
		_setWhitelist(0xA187f22b90526A364423f3BaFaF224711642Ac36,true);
		_setWhitelist(0x4DC2F9416595e80837b9444B808F6Dc900a6D902,true);
		_setWhitelist(0xC0287f9308907083110A136Fe9eb2BED7B6470eF,true);
		_setWhitelist(0x4635Ed5380E1202614816fa85aC4f9fE2A524E63,true);
		_setWhitelist(0xBF2D5CAa41C431C198B10bBcedC3639C458C5Ea3,true);
		_setWhitelist(0x0986BA6E3F9D12a78710a53F90120486AcC400E4,true);
		_setWhitelist(0xC32d882F266c8040B0cca55aF98d09F1F2FB51fA,true);
		_setWhitelist(0xECF151646b12633258A3DF45150497b753a6CD5B,true);
		_setWhitelist(0xEb0bA92B11AcFf7A953c51B60ae62d993aF51d37,true);
		_setWhitelist(0xDC0636916FfbAce800195D122A785F8a0D98F3B6,true);
		_setWhitelist(0xAC97E0721677BfEaa3a7829287b35B4d093E3148,true);
		_setWhitelist(0x4e4173aFe36b8b0F8E9df9F84f70A93A4e85DEd1,true);
		_setWhitelist(0xdE25aFc16b02716d8a3cEA42C663a74F72E05CcA,true);
		_setWhitelist(0x42C66B7BeDD52dCeB30D2DED3115E7fcCD050a18,true);

	
	}
    
    receive() external payable {

	}
    
    function plan() payable public{
        require(boxMap[currentId].status,"This order is not opened");
        require(boxMap[currentId].price >= msg.value," No more quota");
        require(boxMap[currentId].sellBoxAmount < boxMap[currentId].boxAmount,"sell out");
        
        if(whitelist[msg.sender] &&  boxMap[currentId].maxTotalbnb> boxMap[currentId].sellbnb ){
			whitelist[msg.sender] == false;			
            uint256 bnbAmount = boxMap[currentId].bnbAmount;
            boxMap[currentId].sellbnb = boxMap[currentId].sellbnb.add(bnbAmount);
			payable(wallet).transfer(bnbAmount);
        }

        uint256 hopeAmount = randomNum(boxMap[currentId].minHopeAmount,boxMap[currentId].maxHopeAmount);
        hope.transfer(msg.sender, hopeAmount);
        boxMap[currentId].sellHope = boxMap[currentId].sellHope.add(hopeAmount);
        boxMap[currentId].sellBoxAmount = boxMap[currentId].sellBoxAmount.add(1);

        emit Plan(msg.sender, hopeAmount, hopeAmount);

        payable(wallet).transfer(boxMap[currentId].price);
    }

    function randomNum(uint256 _min, uint256 _max)internal returns(uint256) {
        uint256 index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % _max;   
        nonce++;
        return index.add(_min);
    }

    function setWhitelist(address _addr, bool _status) public onlyOwner{
        _setWhitelist(_addr,_status);
    }
	
	function _setWhitelist(address _addr, bool _status) internal{
        whitelist[_addr] = _status;
    }
	
    function setBoxMap(uint256 _boxId, bool _status, uint256 _boxAmount, uint256 _price, uint256 _minHopeAmount, uint256 _maxHopeAmount, uint256 _bnbAmount, uint256 _maxTotalbnb, uint256 _starSaleTime)external onlyOwner{
            _setBoxMap(_boxId, _status, _boxAmount, _price, _minHopeAmount, _maxHopeAmount, _bnbAmount, _maxTotalbnb, _starSaleTime);
    }

    function _setBoxMap(uint256 _boxId, bool _status, uint256 _boxAmount, uint256 _price, uint256 _minHopeAmount, uint256 _maxHopeAmount, uint256 _bnbAmount, uint256 _maxTotalbnb, uint256 _starSaleTime)internal{
            boxMap[_boxId].status = _status;
            boxMap[_boxId].boxAmount = _boxAmount;
            boxMap[_boxId].price = _price;
            boxMap[_boxId].minHopeAmount = _minHopeAmount;
            boxMap[_boxId].maxHopeAmount = _maxHopeAmount;
            boxMap[_boxId].bnbAmount = _bnbAmount;
            boxMap[_boxId].maxTotalbnb = _maxTotalbnb;
            boxMap[_boxId].starSaleTime = _starSaleTime;

    } 

    function lookBoxInfo()public view returns(BoxInfo memory){
        return boxMap[currentId];
    }
    

    
    function setCurrentId(uint256 _currentId) external onlyOwner{
        currentId = _currentId;
    }


    function setWallet(address _wallet)external onlyOwner{
        wallet = _wallet;
    }
    
    function withdrawStuckTokens(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }
    
    function withdrawalETH() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

  
        
    modifier onlyOwner {
        require(manager[msg.sender] == true);
        _;
    }
}