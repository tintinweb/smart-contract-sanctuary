// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
contract Airdrop is Ownable {
    mapping (address => uint256) list;
    IERC20 public token;
    function setToken(IERC20 _token) external onlyOwner {
        token = _token;
    }
    event Bought(uint256 amount);
    event Sold(uint256 amount);
    uint256 public _initialSupply = 100000000000 * 10 ** 18;
    address[] addWhitelist;
    // uint256 public _totalAirdrop = 100000000000 * 0.04 * 10 ** 18;
    uint256 public _totalAirdrop = 3000 * 10 ** 18;
    string public _name = "ELD Token";
    string public _symbol = "ELD";
    uint256 private numTokensAirdrops = 1000 * 10 ** 18;

    uint256 private minSend = 0.00022 * 10 ** 18;
    mapping(address => bool) private airdrops;
    event ClaimAirdrop(uint256 amount);
    function claimAirdrop() payable public {
        uint256 amountTobuy = msg.value;
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy >= minSend, "You need to send 0.1$ to claim airdrop");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        require(!airdrops[msg.sender], "Account was set");
        token.transfer(msg.sender, numTokensAirdrops);
        //super.transferFrom(address(this), msg.sender, numTokensAirdrops);
        airdrops[msg.sender] = true;
        emit ClaimAirdrop(amountTobuy);
    }
    function airdropSend(address[] memory _to, uint256 _value) external onlyOwner returns (bool)  {
        assert(_to.length <= 150);
        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
            assert(token.transfer(_to[i], _value) == true);
        }
        return true;
    }
    
    receive() external payable {
        claimAirdrop();
    }

}