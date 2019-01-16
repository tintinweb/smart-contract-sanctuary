pragma solidity ^0.4.24;

// <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="08726d78786d646166257b6764616c617c7148392639382638">[email&#160;protected]</a> from NPM

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
        uint256 data_criacao;
        string identificador;
        string provaHashArquivo;
        string descricao;
        string empresa;
    }

    mapping(string => Serie) private series;
    string[] public seriesIndex;

    event SeriePublicada(string identificador, string provaHashArquivo, string descricao, string empresa);

    function publishSerie(string _identifier, string _fileHashProof, string _description, string _company) public onlyOwner {
        series[_identifier] = Serie(now, _identifier, _fileHashProof, _description, _company);
        seriesIndex.push(_identifier);

        emit SeriePublicada(_identifier, _fileHashProof, _description, _company);
    }

    function consultarSerie(string _identifier) public view returns (uint256, string, string, string, string) {
        return (
            series[_identifier].data_criacao,
            series[_identifier].identificador,
            series[_identifier].provaHashArquivo,
            series[_identifier].descricao,
            series[_identifier].empresa
        );
    }

}