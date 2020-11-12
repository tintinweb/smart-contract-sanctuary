// Dependency file: contracts/libraries/TransferHelper.sol

//SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0;

library SushiHelper {
    function deposit(address masterChef, uint256 pid, uint256 amount) internal {
        (bool success, bytes memory data) = masterChef.call(abi.encodeWithSelector(0xe2bbb158, pid, amount));
        require(success && data.length == 0, "SushiHelper: DEPOSIT FAILED");
    }

    function withdraw(address masterChef, uint256 pid, uint256 amount) internal {
        (bool success, bytes memory data) = masterChef.call(abi.encodeWithSelector(0x441a3e70, pid, amount));
        require(success && data.length == 0, "SushiHelper: WITHDRAW FAILED");
    }

    function pendingSushi(address masterChef, uint256 pid, address user) internal returns (uint256 amount) {
        (bool success, bytes memory data) = masterChef.call(abi.encodeWithSelector(0x195426ec, pid, user));
        require(success && data.length != 0, "SushiHelper: WITHDRAW FAILED");
        amount = abi.decode(data, (uint256));
    }

    uint public constant _nullID = 0xffffffffffffffffffffffffffffffff;
    function nullID() internal pure returns(uint) {
        return _nullID;
    }
}


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Dependency file: contracts/interface/IWasabi.sol

//SPDX-License-Identifier: MIT
// pragma solidity >=0.5.0;

interface IWasabi {
    function getOffer(address  _lpToken,  uint index) external view returns (address offer);
    function getOfferLength(address _lpToken) external view returns (uint length);
    function pool(address _token) external view returns (uint);
    function increaseProductivity(uint amount) external;
    function decreaseProductivity(uint amount) external;
    function decreaseProductivityAll() external;
    function tokenAddress() external view returns(address);
    function addTakerOffer(address _offer, address _user) external returns (uint);
    function getUserOffer(address _user, uint _index) external view returns (address);
    function getUserOffersLength(address _user) external view returns (uint length);
    function getTakerOffer(address _user, uint _index) external view returns (address);
    function getTakerOffersLength(address _user) external view returns (uint length);
    function offerStatus() external view returns(uint amountIn, address masterChef, uint sushiPid);
    function cancel(address _from, address _sushi, uint amountWasabi) external ;
    function take(address taker,uint amountWasabi) external;
    function payback(address _from) external;
    function close(address _from, uint8 _state, address _sushi) external  returns (address tokenToOwner, address tokenToTaker, uint amountToOwner, uint amountToTaker);
    function upgradeGovernance(address _newGovernor) external;
    function acceptToken() external view returns(address);
    function rewardAddress() external view returns(address);
    function getTokensLength() external view returns (uint);
    function tokens(uint _index) external view returns(address);
    function offers(address _offer) external view returns(address tokenIn, address tokenOut, uint amountIn, uint amountOut, uint expire, uint interests, uint duration);
    function getRateForOffer(address _offer) external view returns (uint offerFeeRate, uint offerInterestrate);
}


// Dependency file: contracts/interface/IERC20.sol

//SPDX-License-Identifier: MIT
// pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// Root file: contracts/WasabiGovernance.sol

pragma solidity >=0.6.6;

// import 'contracts/libraries/TransferHelper.sol';
// import 'contracts/interface/IWasabi.sol';
// import 'contracts/interface/IERC20.sol';

// todo
contract WasabiGovernance  {
    uint public version = 1;
    address public wasabi;
    address public owner;

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);
    event Upgraded(address indexed _from, address indexed _to, uint _value);
    event RewardManagerChanged(address indexed _from, address indexed _to, uint _rewardTokenBalance, uint _wsbTokenBalance);

    modifier onlyOwner() {
        require(msg.sender == owner, 'WasabiGovernance: FORBIDDEN');
        _;
    }

    constructor () public {
        owner = msg.sender;
    }

    function initialize(address _wasabi) external onlyOwner {
        require(_wasabi != address(0), 'WasabiGovernance: INPUT_ADDRESS_IS_ZERO');
        wasabi = _wasabi;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), 'WasabiGovernance: INVALID_ADDRESS');
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    function upgrade(address _newGovernor) external onlyOwner returns (bool) {
        IWasabi(wasabi).upgradeGovernance(_newGovernor);
        return true; 
    }

    function changeRewardManager(address _manager) external onlyOwner returns (bool) {
        address rewardToken = IWasabi(wasabi).acceptToken();
        address wsbToken = IWasabi(wasabi).tokenAddress();
        uint rewardTokenBalance = IERC20(rewardToken).balanceOf(address(this));
        uint wsbTokenBalance = IERC20(wsbToken).balanceOf(address(this));
        require(rewardTokenBalance > 0 || wsbTokenBalance > 0, 'WasabiGovernance: NO_REWARD');
        require(_manager != address(this), 'WasabiGovernance: NO_CHANGE');
        if (rewardTokenBalance > 0) TransferHelper.safeTransfer(rewardToken, _manager, rewardTokenBalance);
        if (wsbTokenBalance > 0) TransferHelper.safeTransfer(wsbToken, _manager, wsbTokenBalance);
        emit RewardManagerChanged(address(this), _manager, rewardTokenBalance, wsbTokenBalance);
        return true;
    }

}