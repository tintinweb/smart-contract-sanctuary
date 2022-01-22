/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

pragma solidity 0.4.23;

/*
╭━━━┳━╮╱╭┳━━━┳━━━┳━━━┳━━━┳━━━╮╭━━━┳━━╮
┃╭━╮┃┃╰╮┃┃╭━╮┃╭━╮┃╭━╮┃╭━━┫╭━╮┃┃╭━━┻┫┣╯
┃╰━━┫╭╮╰╯┃┃╱┃┃╰━╯┃╰━╯┃╰━━┫╰━╯┃┃╰━━╮┃┃
╰━━╮┃┃╰╮┃┃╰━╯┃╭━━┫╭━━┫╭━━┫╭╮╭╯┃╭━━╯┃┃
┃╰━╯┃┃╱┃┃┃╭━╮┃┃╱╱┃┃╱╱┃╰━━┫┃┃╰┳┫┃╱╱╭┫┣╮
╰━━━┻╯╱╰━┻╯╱╰┻╯╱╱╰╯╱╱╰━━━┻╯╰━┻┻╯╱╱╰━━╯
Snapper.fi | Partner Program
Start earn money now: https://snapper.fi/referral.html
**/

contract SnapperPartner {
    mapping(address => bool) public partner;
    address public owner;
    uint256 public tax = 1000000000000000000;
    
    string public link = 'https://snapper.fi';
    string public note = 'none';
    address public recoveryOwner;

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    function SnapperPartner(address _owner, address _recoveryOwner) public {
        owner = _owner;
        recoveryOwner = _recoveryOwner;
    }
    
    function() public payable {}

    function partnerTax() public view returns(uint256) {
        return tax;
    }

    function becomePartner(address _newPartner) public payable {
        owner.transfer(tax);
        partner[_newPartner] = true;
    }

    function becomePartner_auto() public payable {
        owner.transfer(tax);
        partner[msg.sender] = true;
    }

    function addPartner(address _newPartner) public onlyOwner {
        partner[_newPartner] = true;
    }
    function removePartner(address _newPartner) public onlyOwner {
        partner[_newPartner] = false;
    }
    
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

    function newTax(uint256 _newtax) public onlyOwner {
        tax = _newtax;
    }

    function bookmark() public payable {
      owner.transfer(this.balance);
   }
}