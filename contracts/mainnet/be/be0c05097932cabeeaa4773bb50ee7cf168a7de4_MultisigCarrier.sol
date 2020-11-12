// File: contracts/IMultisigCarrier.sol

pragma solidity ^0.5.0;

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract IMultisigCarrier {

    function approveFrom(
        address caller,
        address payable destination,
        address currencyAddress,
        uint256 amount
    ) public returns (bool);

}

// File: contracts/MultisigVault.sol

pragma solidity ^0.5.0;


contract MultisigVault {

    address private _carrier;

    constructor() public {
        _carrier = msg.sender;
    }

    function owner() public view returns (address) {
        return _carrier;
    }

    function approve(
        address payable destination,
        address currencyAddress,
        uint256 amount
    ) public returns (bool) {
        IMultisigCarrier multisigCarrier = IMultisigCarrier(_carrier);
        return multisigCarrier.approveFrom(msg.sender, destination, currencyAddress, amount);
    }

    function external_call(address destination, uint value, bytes memory data) public returns (bool) {
        require(msg.sender == _carrier, "Ownable: caller is not the owner");

        bool result;
        assembly {
            let dataLength := mload(data)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710), // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                0,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }


    function () external payable {}
}

// File: contracts/MultisigCarrier.sol

pragma solidity ^0.5.0;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract MultisigCarrier {

    using SafeMath for uint256;

    struct VaultInfo {
        bool initiated;
        uint8 signatureMinThreshold;
        address[] parties;
    }

    struct Approval {
        uint32 nonce;
        uint8  coincieded;
        bool   finished;
        address[] parties;
    }

    uint32 private _nonce;
    address private _owner;

    mapping(
        address => VaultInfo
    ) private _vaultInfos;

    mapping(
        // MutlisigVault
        address => mapping(
            // Destination
            address => mapping(
                // Currency
                address => mapping(
                    // Amount
                    uint256 => Approval
                )
            )
        )
    ) public _approvals;

    mapping(uint256 => bool) public _finished;

    event NewMultisigCarrierCreated(address multisigCarrierAddress);

    /**
      * @dev Construcor.
      *
      * Requirements:
      * - `_signatureMinThreshold` .
      * - `_parties`.
      */
    constructor() public {
        _owner = msg.sender;
    }


    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(isOwner(), "Caller is not the owner");
        _;
    }


    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }


    function createMultisigVault() public returns (address) {
        MultisigVault multisigVault = new MultisigVault();
        VaultInfo storage vaultInfo = _vaultInfos[address(multisigVault)];
        vaultInfo.initiated = true;

        emit NewMultisigCarrierCreated(address(multisigVault));

        return address(multisigVault);
    }


    function setVaultInfo(
        address vaultAddress,
        uint8 signatureMinThreshold,
        address[] memory parties
    ) public onlyOwner() returns (bool) {
        require(signatureMinThreshold > 0, "Parties are already set");
        require(parties.length > 0 && parties.length <= 10, "Minimum 1, maximum 10 parties");
        require(signatureMinThreshold <= parties.length, "Min signatures mismatches parties array");

        VaultInfo storage vaultInfo = _vaultInfos[vaultAddress];
        vaultInfo.signatureMinThreshold = signatureMinThreshold;
        vaultInfo.parties = parties;

        return true;
    }


    function approve(
        address payable vaultAddress,
        address payable destination,
        address currencyAddress,
        uint256 amount
    ) public returns (bool) {
        approveAndRelease(msg.sender, vaultAddress, destination, currencyAddress, amount);
    }

    function approveFrom(
        address caller,
        address payable destination,
        address currencyAddress,
        uint256 amount
    ) public returns (bool) {
        approveAndRelease(caller, msg.sender, destination, currencyAddress, amount);
    }


    function approveAndRelease(
        address caller,
        address payable vaultAddress,
        address payable destination,
        address currencyAddress,
        uint256 amount
    ) internal returns (bool) {
        VaultInfo storage vaultInfo = _vaultInfos[vaultAddress];

        require(vaultInfo.initiated, "Vault does not exist");
        require(containsParty(vaultInfo.parties, caller), "Not a member");

        if (currencyAddress == etherAddress()) {
            address multisig = address(vaultAddress);  // https://biboknow.com/page-ethereum/78597/solidity-0-6-0-addressthis-balance-throws-error-invalid-opcode
            require(multisig.balance >= amount, "Insufficient balance");
        } else {
            require(IERC20(currencyAddress).balanceOf(address(vaultAddress)) >= amount, "Insufficient balance");
        }

        Approval storage approval = _approvals[vaultAddress][destination][currencyAddress][amount];

        require(!containsParty(approval.parties, caller), "Party already approved");

        if (approval.coincieded == 0) {
            _nonce += 1;
            approval.nonce = _nonce;
        }

        approval.parties.push(caller);
        approval.coincieded += 1;

        if ( approval.coincieded >= vaultInfo.signatureMinThreshold ) {
            _finished[approval.nonce] = true;
            delete _approvals[vaultAddress][destination][currencyAddress][amount];

            releaseFunds(vaultAddress, destination, currencyAddress, amount);
        }

        return false;
    }


    function getNonce(
        address vaultAddress,
        address destination,
        address currencyAddress,
        uint256 amount
    ) public view returns (uint256) {
        Approval storage approval = _approvals[vaultAddress][destination][currencyAddress][amount];

        return approval.nonce;
    }


    function partyCoincieded(
        address vaultAddress,
        address destination,
        address currencyAddress,
        uint256 amount,
        uint256 nonce,
        address partyAddress
    ) public view returns (bool) {
        if ( _finished[nonce] ) {
          return true;
        } else {
          Approval storage approval = _approvals[vaultAddress][destination][currencyAddress][amount];

          require(approval.nonce == nonce, "Nonce does not match");

          return containsParty(approval.parties, partyAddress);
        }
    }


    function releaseFunds(
        address payable vaultAddress,
        address payable destination,
        address currencyAddress,
        uint256 amount
    ) internal {
        MultisigVault multisigVault = MultisigVault(vaultAddress);

        if (currencyAddress == etherAddress()) {
            multisigVault.external_call(destination, amount, "");
        } else {
            multisigVault.external_call(currencyAddress, 0, abi.encodeWithSelector(IERC20(currencyAddress).transfer.selector, destination, amount));
        }
    }


    function containsParty(address[] memory parties, address party) internal pure returns (bool) {
        for (uint256 i = 0; i < parties.length; i++) {
          if ( parties[i] == party ) {
            return true;
          }
        }

        return false;
    }


    function etherAddress() public pure returns (address) {
        return address(0x0);
    }

    function serviceAddress() public pure returns (address) {
        return address(0x0A67A2cdC35D7Db352CfBd84fFF5e5F531dF62d1);
    }
}