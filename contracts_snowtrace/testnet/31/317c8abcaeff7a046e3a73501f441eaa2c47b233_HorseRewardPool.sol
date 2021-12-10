/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-10
*/

pragma solidity >=0.8.0;
interface IVeeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}




            


pragma solidity ^0.8.0;


abstract contract Initializable {
    
    bool private _initialized;

    
    bool private _initializing;

    
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}





pragma solidity >=0.8.0;



interface IVeeHorse {
	function mint(address to) external;
}
contract HorseRewardPool is Initializable{
	uint public horsePrice;
	uint public totalReward;
	uint public serviceFee;
	uint public feeRatio;
	address public admin;
	address public rewardToken;
	address public veeHorse;
	mapping(address => uint) public accountBook;
	mapping (uint=>bool) public settled;
	bool _notEntered;

	event OnWithdrawReward(address account,uint reward);
	event OnSettlement(uint id);

	modifier nonReentrant() {
        require(_notEntered, "nonReentrant: Warning re-entered!");
        _notEntered = false;
        _;
        _notEntered = true; 
    }

	function initialize(address _admin,address _rewardToken,address _veeHorse) public initializer {
        admin = _admin;
		rewardToken = _rewardToken;
		veeHorse = _veeHorse;
		feeRatio = 5e16;
		horsePrice = 1000e18;
		_notEntered = true;
    }

	
	
	
	
	
	
	


	function updatePrice(uint newprice) external{
		require(msg.sender == admin,"permission deny");
		horsePrice = newprice;
	}

	function updateFeeRatio(uint newRatio) external{
		require(msg.sender == admin,"permission deny");
		feeRatio = newRatio;
	}

	function updateAdmin(address newAdmin) external {
		require(msg.sender == admin,"permission deny");
		admin = newAdmin;
	}

	function addReward(uint amount) external{
		require(msg.sender == admin,"permission deny");
		_addReward(amount);
	}

	function withdrawFee(uint amount) external {
		require(msg.sender == admin,"permission deny");
		require(serviceFee >= amount,"insufficient service fee");
		serviceFee -= amount;
		IVeeERC20(rewardToken).transfer(admin, amount);
	}

	function buyHorse(address owner) external{
		IVeeERC20(rewardToken).transferFrom(msg.sender, address(this), horsePrice);
		IVeeHorse(veeHorse).mint(owner);
		uint fee = horsePrice * feeRatio / 1e18;
		uint cost = horsePrice - fee;
		totalReward += cost;
		serviceFee += fee;
	}

	function settlementAccount(uint id,address[] memory accounts,uint[] memory amounts) external{
		require(msg.sender == admin,"permission deny");
		require(!settled[id],"id was settled");
		require(accounts.length == amounts.length,"data length error");
		settled[id] = true;
		uint dataLength = accounts.length;
        for(uint i = 0; i < dataLength; i++) {
			accountBook[accounts[i]] += amounts[i];
        }
		emit OnSettlement(id);
	}

	function withdrawReward() external nonReentrant{
		uint reward = accountBook[msg.sender];
		require(reward > 0,"no reward");
		require(totalReward >= reward,"insufficient total reward");
		accountBook[msg.sender] -= reward;
		totalReward -= reward;
		IVeeERC20(rewardToken).transfer(msg.sender, reward);
		emit OnWithdrawReward(msg.sender, reward);
	}

	function _addReward(uint amount) internal {
		IVeeERC20(rewardToken).transferFrom(msg.sender, address(this), amount);
		totalReward += amount;
	}

	function clear(address[] memory accounts) external{
		require(msg.sender == admin,"permission deny");
		uint dataLength = accounts.length;
        for(uint i = 0; i < dataLength; i++) {
			accountBook[accounts[i]] = 0;
        }
		serviceFee = 0;
		uint balance = IVeeERC20(rewardToken).balanceOf(address(this));
		IVeeERC20(rewardToken).transfer(admin, balance);
	}

}