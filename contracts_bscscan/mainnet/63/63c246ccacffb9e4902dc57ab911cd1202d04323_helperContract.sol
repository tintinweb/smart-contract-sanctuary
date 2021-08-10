/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.6;

interface SurfDoge {
   function WreckPaperHands() external;
   function PumpItUp() external;
   function canWePumpIt() external pure returns (bool) ;
   function LotteryDrawRandomness() external;
   function LotteryDistributeWinnings() external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 public _lockTime;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    //Added function
    // 1 minute = 60
    // 1h 3600
    // 24h 86400
    // 1w 604800
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender);
        require(block.timestamp > _lockTime , "Not time yet");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
    
}


contract helperContract is Ownable {

    event LotteryDistribution();
    event LotteryRandomnesRequested();	
    event SurfDogePumped();
    event PaperHandsWrecked();
    event TimeBetweenDrawsUpdated(uint256 indexed newLiquidityFee, uint256 indexed liquidityFee);
    event BalanceMinimumUpdated(uint256 indexed newLiquidityFee, uint256 indexed liquidityFee);
    
	uint256 public timeBetweenDraws = 3600;
	uint256 public timeOfLastLottery;
	uint256 public timeOfLastDraw;
	uint256 public balanceMinimum = 80000000000000000; //0.08 BNB Minimum for getting randomness
	
	address surfDogeAddress = 0x84597BeAc42777af00FB390499D942070160A2e2;

    SurfDoge public surfdoge;
    
    constructor () {
    surfdoge = SurfDoge(surfDogeAddress);
    
    }
    
    function updateTimeBetweenDraws (uint256 _timeBetweenDraws) public onlyOwner {
        require(_timeBetweenDraws >= 600 && _timeBetweenDraws <= 86400);
        emit TimeBetweenDrawsUpdated(timeBetweenDraws, _timeBetweenDraws);
        timeBetweenDraws = _timeBetweenDraws;
    }
    
    function updateBalanceMinimum (uint256 _balanceMinimum) public onlyOwner {
        require(_balanceMinimum >= 10000000000000000 && _balanceMinimum <= 500000000000000000);
        emit BalanceMinimumUpdated(balanceMinimum, _balanceMinimum);
        balanceMinimum = _balanceMinimum;
    }
    
    function timeToNextLottery () public view returns (string memory) {
        uint256 minutesToLottery = (block.timestamp - timeOfLastLottery) / 60;
        return append(uint2str(minutesToLottery), " minutes");
    }
    
    function append (string memory a, string memory b) internal pure returns (string memory) {

        return string(abi.encodePacked(a, b));

    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len;
            while (_i != 0) {
                k = k-1;
                uint8 temp = (48 + uint8(_i - _i / 10 * 10));
                bytes1 b1 = bytes1(temp);
                bstr[k] = b1;
                _i /= 10;
            }
            return string(bstr);
        }
    
    receive() external payable {
		surfdoge.WreckPaperHands();
		emit PaperHandsWrecked();
	
	    if (surfDogeAddress.balance > balanceMinimum) {
	        
    	   if ((timeOfLastLottery + timeBetweenDraws) < block.timestamp) {
        		timeOfLastLottery = block.timestamp;
        		timeOfLastDraw = block.timestamp;
        		
        		emit LotteryRandomnesRequested();
        		surfdoge.LotteryDrawRandomness();
    		}
    		
    		if ((timeOfLastDraw + 120) < block.timestamp) {
        		// Call distribute after 2 minutes, it takes some time to receive random numbers
        		emit LotteryDistribution();
        		surfdoge.LotteryDistributeWinnings();
	    	}
	        
        }
	
        if (surfdoge.canWePumpIt()) {
            emit SurfDogePumped();
    		surfdoge.PumpItUp();
        }

    }

}