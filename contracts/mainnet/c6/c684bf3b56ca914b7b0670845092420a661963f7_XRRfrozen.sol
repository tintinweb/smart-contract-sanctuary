pragma solidity ^0.4.18;


contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract XRRtoken {
    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool);
}

contract XRRfrozen is Ownable {

    XRRtoken token;

    struct Vault {
        address wallet;
        uint256 amount;
        uint unfrozen;
    }

    Vault[] public vaults;


    function XRRfrozen() public {
        // Bounty May 16, 2018 12:00:00 AM
        vaults.push(Vault(0x3398BdC73b3e245187aAe7b231e453c0089AA04e, 1500000 ether, 1526428800));
        // Airdrop May 16, 2018 12:00:00 AM
        vaults.push(Vault(0x0B65Ce79206468fdA9E12eC77f2CEE87Ff63F81C, 1500000 ether, 1526428800));
        // Stakeholders February 9, 2019 12:00:00 AM
        vaults.push(Vault(0x3398BdC73b3e245187aAe7b231e453c0089AA04e, 15000000 ether, 1549670400));
    }

    function setToken(XRRtoken _token) public onlyOwner {
        token = _token;
    }

    function unfrozen() public {
        require(notEmpty());
        uint8 i = 0;
        while (i++ < vaults.length) {
            if (now > vaults[i].unfrozen && vaults[i].amount > 0) {
                token.transfer(vaults[i].wallet, vaults[i].amount);
                vaults[i].amount = 0;
            }
        }
    }

    function notEmpty() public view returns (bool){
        uint8 i = 0;
        while (i++ < vaults.length) {
            if (now > vaults[i].unfrozen && vaults[i].amount > 0) {
                return true;
            }
        }
        return false;
    }

    function tokenTosale() public view returns (uint256){
        return token.balanceOf(this);
    }
}