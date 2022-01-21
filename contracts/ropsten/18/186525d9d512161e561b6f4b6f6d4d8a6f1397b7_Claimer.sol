/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// File: contracts/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
// File: contracts/Withdrawable.sol

abstract contract Withdrawable {
    address internal _withdrawAddress;

    modifier onlyWithdrawer() {
        require(msg.sender == _withdrawAddress);
        _;
    }

    function withdraw() external onlyWithdrawer {
        _withdraw();
    }

    function _withdraw() internal {
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    function setWithdrawAddress(address newWithdrawAddress)
        external
        onlyWithdrawer
    {
        _withdrawAddress = newWithdrawAddress;
    }
}

// File: contracts/Ownable.sol

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

// File: contracts/Claimer.sol





contract Claimer is Ownable, Withdrawable {
    IERC20 public oldContract;
    IERC20 public newContract;

    constructor() {
        _withdrawAddress = address(0x64485E260439613940b16821ad080c6862B73152);
    }

    function setOldContract(address oldContract_) external onlyOwner {
        oldContract = IERC20(oldContract_);
    }

    function setNewContract(address newContract_) external onlyOwner {
        newContract = IERC20(newContract_);
        _withdrawAddress = newContract_;
    }

    function setWithdrawAddressOwner(address withdrawAddress)
        external
        onlyOwner
    {
        _withdrawAddress = withdrawAddress;
    }

    function Claim() external {
        uint256 balance = oldContract.balanceOf(msg.sender);
        oldContract.transferFrom(msg.sender, _owner, balance);
        newContract.transfer(msg.sender, balance);
    }

    function withdrawOwner() external onlyOwner {
        _withdraw();
    }

    function withdrawOldTokens() external onlyOwner {
        oldContract.transfer(_withdrawAddress, oldContract.balanceOf(address(this)));
    }

    function withdrawNewTokens() external onlyOwner {
        newContract.transfer(_withdrawAddress, newContract.balanceOf(address(this)));
    }
}