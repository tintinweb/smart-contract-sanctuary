// SPDX-License-Identifier: UNLICENSED
// author: Popcorn (https://popcorn.network)

pragma solidity ^0.8.0;

/**
 * @title Crypto Climate Accord on-chain Agreement provided by Popcorn.Network
 * @notice by calling `acceptCryptoClimateAccordAgreement()` function in this contract, `msg.sender` is committing to the terms of the following:
 *  Signing this transaction represents a public commitment to support the overall and interim objectives of the Crypto Climate Accord, as follows:
 *  The Crypto Climate Accord’s overall objective is to decarbonize the global crypto industry by prioritizing climate stewardship and supporting the entire crypto industry’s transition to net zero greenhouse gas emissions by 2040. The Accord has two specific interim objectives:
 *
 *  Objective 1: Achieve net-zero emissions from electricity consumption for CCA Signatories by 2030.
 *  Objective 2: Develop standards, tools, and technologies with CCA Supporters to accelerate the adoption of and verify progress toward 100% renewably-powered blockchains by the 2025 UNFCCC COP30 conference.
 *
 *  Moreover, by signing this transaction, the Signatory, affirms its public commitment to achieve net-zero emissions
 *  from electricity consumption associated with all of its crypto-related operations and to report progress toward this net-zero emissions target using best industry practices.
 *
 *  By signing and submitting this transaction, Signatory permits full public recognition (including the use of Signatory’s logo and references in public communications) and responsibilities of this commitment.
 *  Please submit the transaction hash via email to the Crypto Climate Accord to formalize this commitment and put this commitment on record. If Signatory decides to withdraw its commitment, then Signatory must submit its withdrawal in writing to Energy Web to formalize its withdrawal as a Signatory.
 */
contract CryptoClimateAccord {
  mapping(address => bytes32) public metadata;

  /**
   * @param account address of signatory
   * @param acceptedTerms signatory accepts terms
   * @param withdrawn signatory withdrawn from CryptoClimateAccord
   * @param metadata Each signatory will provide an IPFS cid with the following metadata in a valid JSON format below:
   * 
    {
      organizationName: string;
      address: string;
      logo: string;
    }
   *
   */
  struct Signatory {
    address account;
    bool acceptedTerms;
    bool withdrawn;
    bytes32 metadata;
  }

  /**
   * @notice mapping of signatories and their acceptance of terms
   */
  mapping(address => Signatory) public signatories;

  address[] public signatoriesList;

  event SignatoryAdded(address _address);
  event SignatoryRemoved(address _address);

  /**
   * @notice by submitting this transaction, `msg.sender` is committing to the terms of the following:
   *  Signing this transaction represents a public commitment to support the overall and interim objectives of the Crypto Climate Accord, as follows:
   *  The Crypto Climate Accord’s overall objective is to decarbonize the global crypto industry by prioritizing climate stewardship and supporting the entire crypto industry’s transition to net zero greenhouse gas emissions by 2040. The Accord has two specific interim objectives:
   *
   *  Objective 1: Achieve net-zero emissions from electricity consumption for CCA Signatories by 2030.
   *  Objective 2: Develop standards, tools, and technologies with CCA Supporters to accelerate the adoption of and verify progress toward 100% renewably-powered blockchains by the 2025 UNFCCC COP30 conference.
   *
   *  Moreover, by signing this transaction, the Signatory, affirms its public commitment to achieve net-zero emissions
   *  from electricity consumption associated with all of its crypto-related operations and to report progress toward this net-zero emissions target using best industry practices.
   *  By signing and submitting this transaction, Signatory permits full public recognition (including the use of Signatory’s logo and references in public communications) and responsibilities of this commitment.
   *  Please submit the transaction hash via email to the Crypto Climate Accord to formalize this commitment and put this commitment on record. If Signatory decides to withdraw its commitment, then Signatory must submit its withdrawal in writing to Energy Web to formalize its withdrawal as a Signatory.
   *
   */
  function acceptCryptoClimateAccordAgreement(bytes32 _metadata, bool _acceptTerms) external {
    require(_metadata != "", "Metadata submitted should not be empty");
    require(!signatories[msg.sender].acceptedTerms, "Signatory already exists");
    require(_acceptTerms == true, "Signatory must accept terms of agreement");

    signatories[msg.sender] = Signatory({
      account: msg.sender,
      acceptedTerms: _acceptTerms,
      withdrawn: false,
      metadata: _metadata
    });

    signatoriesList.push(msg.sender);
    emit SignatoryAdded(msg.sender);
  }

  /**
   * @notice by submitting this transaction, `msg.sender` is withdrawing their commitment to the Crypto Climate Accord
   */
  function withdrawFromCryptoClimateAccordAgreement() external {
    require(signatories[msg.sender].acceptedTerms, "Must be a signatory to withdraw from Crypto Climate Accord");
    signatories[msg.sender].withdrawn = true;
    signatories[msg.sender].acceptedTerms = false;
    emit SignatoryRemoved(msg.sender);
  }

  /**
   * @notice check whether address is a signatory
   */
  function isASignatory(address _address) external view returns (bool) {
    return signatories[_address].acceptedTerms && !signatories[_address].withdrawn;
  }

  /**
   * @notice retrieve bytes32 encoded IPFS cid for signatory metadata
   */
  function getSignatoryMetadata(address _address) external view returns (bytes32) {
    require(signatories[_address].acceptedTerms, "Address is not a signatory");
    return signatories[_address].metadata;
  }

  /**
   * @notice Returns list of signatories. Entries need to be validated against `isASignatory()` in case signatory has withdrawn from agreement
   */
  function getSignatories() external view returns (address[] memory) {
    return signatoriesList;
  }
}