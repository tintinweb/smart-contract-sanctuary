pragma solidity ^0.4.24;

// <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="aed4cbdedecbc2c7c083ddc1c2c7cac7dad7ee9f809f9e809e">[email&#160;protected]</a> from NPM

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract LottoCapSeries is Ownable {

    struct Serie {
        uint256 created;
        string identifier;
        string fileHashProof;
        string description;
    }

    mapping(string => Serie) private series;
    string[] public seriesIndex;

    event SeriePublished(string identifier, string fileHashProof, string description);

    function publishSerie(string _identifier, string _fileHashProof, string _description) public onlyOwner {
        series[_identifier] = Serie(now, _identifier, _fileHashProof, _description);
        seriesIndex.push(_identifier);

        emit SeriePublished(_identifier, _fileHashProof, _description);
    }

    function getSerie(string _identifier) public view returns (uint256, string, string, string) {
        return (
            series[_identifier].created,
            series[_identifier].identifier,
            series[_identifier].fileHashProof,
            series[_identifier].description
        );
    }

}