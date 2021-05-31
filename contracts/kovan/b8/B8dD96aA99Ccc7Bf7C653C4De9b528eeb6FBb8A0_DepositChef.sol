/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity >=0.6.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IGateway {
    function mint(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
    function burn(bytes calldata _to, uint256 _amount) external returns (uint256);
}

contract DepositChef {
    uint256 public accumulatedRewards;
    IERC20 public rewardToken;
    IGateway public rewardTokenGateway;
    
    event Deposit(uint256 _amount, bytes _msg);

    constructor() {
        accumulatedRewards = 0;
        rewardToken = IERC20(0x42805DA220DF1f8a33C16B0DF9CE876B9d416610);
        rewardTokenGateway = IGateway(0xAACbB1e7bA99F2Ed6bd02eC96C2F9a52013Efe2d);
    }
    
    function deposit(
        // Parameters from users
        bytes calldata _msg,
        // Parameters from Darknodes
        uint256        _amount,
        bytes32        _nHash,
        bytes calldata _sig
    ) external {
        bytes32 pHash = keccak256(abi.encode(_msg));
        uint256 mintedAmount = rewardTokenGateway.mint(pHash, _amount, _nHash, _sig);
        accumulatedRewards = accumulatedRewards + mintedAmount;
        emit Deposit(mintedAmount, _msg);
    }

    function balance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }
}