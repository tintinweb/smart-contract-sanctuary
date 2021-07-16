//SourceUnit: CherrySwap.sol

pragma solidity ^0.5.8;

interface TRC20 {
    function totalSupply() external view returns (uint256 theTotalSupply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function mintTo(address account, uint256 amount) external;
}

contract CherrySwap {
    TRC20 oldToken;
    TRC20 newToken;
    uint256 startTime = 1599919200;
    uint256 endTime = startTime + (1 days);

    constructor(address _oldToken, address _newToken) public {
        oldToken = TRC20(_oldToken);
        newToken = TRC20(_newToken);
    }

    function transferCherry() public returns (bool) {
        require(
            block.timestamp > startTime && block.timestamp < endTime,
            "Must be in time!!"
        );
        uint256 oldBalance = oldToken.balanceOf(msg.sender);
        oldToken.transferFrom(msg.sender, address(this), oldBalance);
        newToken.mintTo(msg.sender, oldBalance / 10);
    }
}