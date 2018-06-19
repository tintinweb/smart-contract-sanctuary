/*
The goico_kasko2go Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The goico_kasko2go Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the goico_kasko2go Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <<span class="__cf_email__" data-cfemail="bfd691ccc9d6cdd6d1ffcfcdd0c9dacd91d6d0">[email&#160;protected]</span>>
*/

pragma solidity ^0.4.19;

contract owned {

    address public owner;
    address public candidate;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        candidate = _owner;
    }

    function confirmOwner() public {
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }
}

contract BaseERC20 {
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
}

contract Token is owned {

    string  public standard = &#39;Token 0.1&#39;;
    string  public name     = &#39;_K2G&#39;;
    string  public symbol   = &#39;_K2G&#39;;
    uint8   public decimals = 8;

    uint                      public totalSupply;
    mapping (address => uint) public balanceOf;

    uint                      public numberOfInvestors;
    mapping (address => bool) public investors;
    mapping (address => uint) public depositedCPT;
    mapping (address => uint) public depositedWei;

    event Transfer(address indexed from, address indexed to, uint value);

    enum State {
        NotStarted,
        Started,
        Finished
    }

    address public backend;
    address public cryptaurToken = 0x88d50B466BE55222019D71F9E8fAe17f5f45FCA1;
    uint    public tokenPriceInWei;
    State   public state;

    event Mint(address indexed minter, uint tokens, bytes32 originalTxHash);

    constructor() public owned() {}

    function startCrowdsale() public onlyOwner {
        require(state==State.NotStarted);
        state=State.Started;
    }

    function finishCrowdsale() public onlyOwner {
        require(state==State.Started);
        state=State.Finished;
    }

    function changeBackend(address _backend) public onlyOwner {
        backend = _backend;
    }

    function setTokenPriceInWei(uint _tokenPriceInWei) public {
        require(msg.sender == owner || msg.sender == backend);
        tokenPriceInWei = _tokenPriceInWei;
    }

    function () payable public {
        require(state==State.Started);
        uint tokens = msg.value / tokenPriceInWei * 100000000;
        require(balanceOf[msg.sender] + tokens > balanceOf[msg.sender]); // overflow
        require(tokens > 0);
        depositedWei[msg.sender]+=msg.value;
        balanceOf[msg.sender] += tokens;
        if (!investors[msg.sender]) {
            investors[msg.sender] = true;
            ++numberOfInvestors;
        }
        emit Transfer(this, msg.sender, tokens);
        totalSupply += tokens;
    }

    function depositCPT(address _who, uint _valueCPT, bytes32 _originalTxHash) public {
        require(msg.sender == backend || msg.sender == owner);
        require(state==State.Started);
        // decimals in K2G and PROOF are the same and equal 8
        uint tokens = (_valueCPT * 10000) / 238894; // 1 K2G = 23,8894 CPT
        depositedCPT[_who]+=_valueCPT;
        require(balanceOf[_who] + tokens > balanceOf[_who]); // overflow
        require(tokens > 0);
        balanceOf[_who] += tokens;
        totalSupply += tokens;
        if (!investors[_who]) {
            investors[_who] = true;
            ++numberOfInvestors;
        }
        emit Transfer(this, _who, tokens);
        emit Mint(_who, tokens, _originalTxHash);
    }

    function withdraw() public onlyOwner {
        require(msg.sender.call.gas(3000000).value(address(this).balance)());
        uint balance = BaseERC20(cryptaurToken).balanceOf(this);
        BaseERC20(cryptaurToken).transfer(msg.sender, balance);
    }

    // untistupids function
    function transferAnyTokens(address _erc20, address _receiver, uint _amount) public onlyOwner {
        BaseERC20(_erc20).transfer(_receiver, _amount);
    }
}