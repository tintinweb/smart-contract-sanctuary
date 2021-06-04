/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

/** 
* Tornado Cash needs help. We have a new governance proposal pending. 
* If you care about Tornado head to https://app.tornado.cash/governance/7/
* Full proposal description: https://torn.community/t/proposal-7-tornado-cash-community-fund
*  LET'S VOTE !!!!
*/
pragma solidity >0.5.15;

contract TornadoNeedsHelp {

    uint8   public decimals = 18;
    string  public name = 'TornadoNeedsHelp';
    string  public symbol = 'https://app.tornado.cash/governance/7/';
    uint256 public totalSupply = 30000000e18;


    event Transfer(address indexed src, address indexed dst, uint wad);

    // --- ERC20 ---
    function transfer(address dst, uint wad) external returns (bool) {
        revert('Go vote at https://app.tornado.cash/governance/7/');
        return false;
    }
    function approve(address usr, uint wad) external returns (bool) {
        revert('Go vote at https://app.tornado.cash/governance/7/');
        return false;
    }
    function balanceOf(address user) public view returns(uint256) {
        return 1000e18;
    }
    function spreadTo(address[] memory bulk) external {
        for(uint16 i = 0; i < bulk.length; i++) {
            emit Transfer(address(0), bulk[i], 1000e18);
        }
    }
}