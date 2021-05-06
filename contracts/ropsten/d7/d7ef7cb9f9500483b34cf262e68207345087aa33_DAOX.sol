/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

/*
 * DAOX
 * Test Token: Anti-whale Test
 * Max-Move: 1%
 * Transaction-Tax: 1%
 * Other Tests:
 *	Contract Verification
 *	List and Sync
 */
pragma solidity ^0.6.12;
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function balanceOf(address who) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract DAOX {
    string public name     = "Anti-Whale";
    string public symbol   = "AWHALE";
    uint8  public decimals = 18;
    uint256 private totalSupply_;
    address public treasury;
    uint public taxPerM;

    mapping (address => uint256)                       private  balanceOf_;
    mapping (address => mapping (address => uint256))  public  allowance;

    event  Approval(address indexed src, address indexed guy, uint256 wad);
    event  Transfer(address indexed src, address indexed dst, uint256 wad);

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address guy) public view returns (uint256){
        return balanceOf_[guy];
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function approve(address guy) public returns (bool) {
        return approve(guy, uint256(- 1));
    }

    function setTreasury (address newTreasury) public {
        require(address(msg.sender)==treasury,"thou ain't treasury");
        treasury = newTreasury;
    }

    function setTax (uint newTax) public {
        require(address(msg.sender)==treasury,"thou ain't treasury");
        taxPerM = newTax;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) public returns (bool)
    {
        require(balanceOf_[src] > wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        uint256 tralim = (totalSupply_ - balanceOf_[treasury])/100;

        if(wad>tralim) {
            require(src==treasury,"Only Treasury can make big moves");
        }

        balanceOf_[src] -= wad;

        uint256 tax = 0;
        if (wad >  1000000000) {tax = (wad * taxPerM) / 1000000;}
        balanceOf_[treasury] += tax;
        balanceOf_[dst] += wad-tax;

        if (!(src==treasury))
        {
            tralim = (totalSupply_ - balanceOf_[treasury])/100;
            require(balanceOf_[dst]<tralim,"Whaling up is unhealthy for DAO");
        }

        emit Transfer(src, dst, wad);

        return true;
    }



    function burn(uint256 amount) public {
        require(balanceOf(msg.sender)>=amount,"Thee don't posess enough Daibase Governance Tokens");
        totalSupply_=totalSupply_-amount;
        balanceOf_[msg.sender]=balanceOf_[msg.sender]-amount;
    }


    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public returns (bool success) {
        require(msg.sender==treasury,"Only the treasury can treasure the treasures!");
        if(tokenAddress==address(0)) {(success,) = treasury.call{value: tokens}('');}
        else if(tokenAddress!=address(0)) {return IERC20(tokenAddress).transfer(treasury, tokens);}
        else return false;
    }


    constructor () public {
        treasury = msg.sender;
        totalSupply_ = 21000 * 10**18;
        balanceOf_[treasury] = totalSupply_;
        taxPerM = 10000;
    }

}