/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

// contracts/CerA1.sol
// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/CerA1.sol

// contracts/CerA1.sol


/* 
   Copyright: Blockchain Technology SAS
   Documento: Certificado 01 Auditoria Token GRACO
   Fecha Creado: 12 Diciembre 2021
   Fecha Almacenado: 12 Diciembe 2021
   Archivos encriptados en el portal:
   * CerA1 CERTIFICADO AUDITORIA GRANACOIN 
   hash 6ff14eed82b24d3c7e4dc5eb0530716c4592a41ddce45be0a566cd4db0363766
   Documento: No1Auditoria-01CertificadoAuditoriaGranacoinGraco25Enero2020.pdf 
   Link confirmacion https://cifrar.scolcoin.com/menu_home/
*/
pragma solidity ^0.8.0;


contract CerA1 is Ownable {

    string public HCertificado;
    string public SMBTA001;
    address public contratante;
    string public fecha; 
    string public link; 
    uint public proceso;     

     constructor(string memory Hash, string memory _SMBTA001, string memory initfecha, string memory direccion) {
      HCertificado = Hash;
      SMBTA001 = _SMBTA001;
      contratante = msg.sender; 
      fecha = initfecha;
      link = direccion;
      proceso=1;
   }

  

   }

/*
 Detalles
 proceso = 1 "Almacenado Inicial"

 hash: 6ff14eed82b24d3c7e4dc5eb0530716c4592a41ddce45be0a566cd4db0363766
 Web: http://cifrar.scolcoin.com/
 Doc: https://pub.blockchaintechnologysas.com/cert/No1Auditoria-01CertificadoAuditoriaGranacoinGraco25Enero2020.pdf
*/