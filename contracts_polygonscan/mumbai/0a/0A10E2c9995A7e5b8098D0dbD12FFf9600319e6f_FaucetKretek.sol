/**
 *Submitted for verification at polygonscan.com on 2022-01-14
*/

// File: contracts/1_Storage.sol

pragma solidity 0.8.0;

// SPDX-License-Identifier: Unlicensed

interface IERC20 {
    function mint(address _to, uint256 _value) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address _owner) external view returns (uint256 balance);
}

contract FaucetKretek {

    struct Data {
        uint weiPerClaim;
        uint blockDelta;
    }

    mapping ( address => mapping (address => uint)) claimBlocks;
    mapping (address => Data) claimTokenInfo;

    constructor () {
        owner = msg.sender;
    }

    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function transferOnwership(address _owner) public onlyOwner {
        owner = _owner;
    }

    function mutateTokenInfo(uint _weiPerClaim, uint _blockDelta, address token) public onlyOwner {
        claimTokenInfo[token] = Data({
            weiPerClaim: _weiPerClaim,
            blockDelta: _blockDelta
        });
    }

    function faucet(address token) public {
        require(claimBlocks[token][msg.sender] + claimTokenInfo[token].blockDelta < block.number,
         "already claimed in this period");
        IERC20(token).transfer(msg.sender,claimTokenInfo[token].weiPerClaim);
        claimBlocks[token][msg.sender] = block.number;
    }
}