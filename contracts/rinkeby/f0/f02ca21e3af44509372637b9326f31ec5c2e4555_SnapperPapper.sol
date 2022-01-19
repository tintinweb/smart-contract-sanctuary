/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

pragma solidity 0.4.23;

/*
╭━━━┳━╮╱╭┳━━━┳━━━┳━━━┳━━━┳━━━╮╭━━━┳━━╮
┃╭━╮┃┃╰╮┃┃╭━╮┃╭━╮┃╭━╮┃╭━━┫╭━╮┃┃╭━━┻┫┣╯
┃╰━━┫╭╮╰╯┃┃╱┃┃╰━╯┃╰━╯┃╰━━┫╰━╯┃┃╰━━╮┃┃
╰━━╮┃┃╰╮┃┃╰━╯┃╭━━┫╭━━┫╭━━┫╭╮╭╯┃╭━━╯┃┃
┃╰━╯┃┃╱┃┃┃╭━╮┃┃╱╱┃┃╱╱┃╰━━┫┃┃╰┳┫┃╱╱╭┫┣╮
╰━━━┻╯╱╰━┻╯╱╰┻╯╱╱╰╯╱╱╰━━━┻╯╰━┻┻╯╱╱╰━━╯
Snapper.fi | Flash Loan Arbitrage Protocol
Start earn money now: https://snapper.fi/referral
**/

contract SnapperPapper {
    address public owner;
    string public link = 'https://snapper.fi';
    string public note = 'none';
    address public recoveryOwner;

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    function SnapperPapper(address _owner, address _recoveryOwner) public {
        owner = _owner;
        recoveryOwner = _recoveryOwner;
    }
    
    function() public payable {}
    
    
    function newOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    function updateLink(string _newLink) public onlyOwner {
        link = _newLink;
    }
    
    function updateNote(string _newNote) public onlyOwner {
        note = _newNote;
    }
    
    function recoveryOwner(address _newrecoveryOwner) public {
        require(msg.sender == recoveryOwner);
        owner = recoveryOwner;
        recoveryOwner = _newrecoveryOwner;
    }

    function bookmark() public payable {
      owner.transfer(this.balance);
   }
}