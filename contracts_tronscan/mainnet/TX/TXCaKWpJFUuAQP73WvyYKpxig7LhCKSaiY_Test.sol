//SourceUnit: Test.sol

pragma solidity ^0.8.0;


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Test {
    address public stakeToken;

    constructor(address _stakeToken){
        stakeToken = _stakeToken;
    }

    function take() public {
        IERC20(stakeToken).transfer(msg.sender, 10000);
    }
}