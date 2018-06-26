pragma solidity ^0.4.23;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
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

// File: contracts/PhenomenonsContract.sol

contract PhenomenonsContract is Ownable {

    struct Phenomenon {
        string mnemonic;
        string description;
        string category;
        uint8 valueDecimalPlaces;
        bool enabled;
        bool exists;
    }

    mapping(bytes32 => Phenomenon) public phenomenons;
    string[] public mnemonics;

    event PhenomenonAdd(bytes32 hash);
    event PhenomenonDisable(bytes32 hash);
    event PhenomenonEnable(bytes32 hash);

    function addPhenomenon(
        string mnemonic,
        string description,
        string category,
        uint8 valueDecimalPlaces
    ) public onlyOwner
    {
        bytes32 hash = keccak256(abi.encodePacked(mnemonic));
        require(bytes(phenomenons[hash].mnemonic).length == 0, &quot;Phenomenon already exists!&quot;);

        Phenomenon memory phenomenon = Phenomenon(
            mnemonic,
            description,
            category,
            valueDecimalPlaces,
            true,
            true
        );

        phenomenons[hash] = phenomenon;
        mnemonics.push(mnemonic);

        emit PhenomenonAdd(hash);
    }

    function disablePhenomenon(bytes32 _hash) public onlyOwner {
        require(phenomenons[_hash].enabled == true);

        phenomenons[_hash].enabled = false;

        emit PhenomenonDisable(_hash);
    }

    function enablePhenomenon(bytes32 _hash) public onlyOwner {
        require(phenomenons[_hash].exists == true);
        require(phenomenons[_hash].enabled == false);

        phenomenons[_hash].enabled = true;

        emit PhenomenonEnable(_hash);
    }

    function mnemonicsCount() public view returns(uint) {
        return mnemonics.length;
    }

    function isEnabled(bytes32 _hash) public view returns(bool) {
        return phenomenons[_hash].enabled;
    }
}