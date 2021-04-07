/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
                                              N     .N
                                            .ONN.   NN
                                          ..NNDN  :NNNN
                                         .8NN  NNNN. NN
                                        NNN. .NNN....NN
                                    ..NNN ~NNNO     .N:
                                 .,NNNDNNNN?.       NN
                    ..?NNNNNNNNNNNNNNND..          NN
               ..$NNNNN$.    .=NNN=             ..NN
             .NNNN,         .NNON               NNN
           NNN+.           NN~.NN           ..NNN
         NNN..            NN.  ON          .NNN
      .:NN.              ,N=    NN.    .,NNNN
      NNI.              .NN     .NNNNNNNN$.,N?
    ,NN.                .NI     .NNN,.   .  NN.
    NN .                ?N.       ?NNNNNN... NN
    NN.                 NN=       ..NN .NNNN NN
     NN                 NNN.         NN..NN.  NN
     IN.                NNN.          :NNN=   :N,
      NN.               N$NN..         .NN.   .NN
      .NN.              N7 NN .               .NNI
        NN.             NO  DNN  .          .ZNNNN.
        .NN             NN .  NNN:..     ..NNN. .NN
         .NN.           NN .  . INNNNNNNNNNNN:. .ZN
           NNI.         NN       . NNNN+   .ONNN8 NN
             NN.        .N.     .NN, $NN?   . .INNN
              NN?       .NN    NNO     :NNNNNNNN+
               ~NN      .NN   NN,
                .NNN.     NI..NI.
                   NNN    NN.NN
                    .NND.. NNNI
                       NNN.$NN.
                         ONNNN?
                            NNN

   ,        ,     II   N        NN     OOOOOO       SSSS
   M        M     II   NN       NN   OOOOOOOOOO    SSSSSSS
   MM      MM     II   NNN      NN  OOO      OOO  SS     SS
   MMM    MMM     II   NNNN     NN OO?        OO  SS
  MM~MM  MMMMM    II   NN NNN   NN OO         OO$  SSSSSS
  MM MM  MM MM    II   NN  NNN  NN OO         OO=     SSSS
  MM  MMMM  MM    II   NN   NNN:NN .OOO      OOO        SS
 MM    MM    MM   II   NN    NNNNN  =OOO    OOO   SS    SS
 MM    MM    MM   II   NN     NNNN    OOOOOOO      SSSSSS

 TTTTTTTTTTTTTT RRRRRRR   UU     UU   SSSSSS  TTTTTTTTTTTTTT
      TTTT      RR    RR  UU     UU  SS    SS      TTTT
      TTTT      RRRRRRR   UU     UU  SS            TTTT
      TTTT      RR RR     UU     UU   SSSSSS       TTTT
      TTTT      RR  RR    UU     UU        SS      TTTT
      TTTT      RR   RR   UUU   UUU  SS    SS      TTTT
      TTTT      RR    RR   UUUUUUU    SSSSSS       TTTT
*/

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address payable private _owner;

  /**
   * Event that notifies clients about the ownership transference
   * @param previousOwner Address registered as the former owner
   * @param newOwner Address that is registered as the new owner
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns (address payable) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == _owner, "Ownable: Caller is not the owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: New owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 * @title MinosTrust
 * @dev Contract for MinosTrust
 **/
contract MinosTrust is Ownable {

  string public constant name = "MinosTrust";
  string public constant symbol = "MNST";

  mapping (string => string) public registry;

  /**
   * Event that notifies the creation of a new register
   * @param identifier The register unique identifier string
   * @param data The register data string
   */
  event RegisterAdded(
    string indexed identifier,
    string data
  );

  /**
   * Event that notifies the update of an existing register
   * @param identifier The register unique identifier string
   * @param data The register data string
   */
  event RegisterUpdated(
    string indexed identifier,
    string data
  );

  /**
   * Event that notifies the removal of an existing register
   * @param identifier The register unique identifier string
   */
  event RegisterRemoved(
    string indexed identifier
  );

  /**
   * @dev Constructor
   */
  constructor() {
    require(msg.sender != address(0), "MinosTrust: Create contract from the zero address");
  }

  /**
   * @dev Allows to create a new entry in the contract register
   * @param identifier The register unique identifier string
   * @param data The register data string
   */
  function addRegister(string calldata identifier, string calldata data) external onlyOwner {
    require(bytes(registry[identifier]).length == 0, "MinosTrust: Error registering identifier. It already exists.");
    registry[identifier] = data;
    emit RegisterAdded(identifier, data);
  }

  /**
   * @dev Allows to update the data for an existing register entry
   * @param identifier The register unique identifier string
   * @param data The register data string
   */
  function updateRegister(string calldata identifier, string calldata data) external onlyOwner {
    require(bytes(registry[identifier]).length > 0, "MinosTrust: Error updating register. Identifier not found.");
    registry[identifier] = data;
    emit RegisterUpdated(identifier, data);
  }

  /**
   * @dev Allows to remove the data for an existing register entry
   * @param identifier The register unique identifier string
   */
  function removeRegister(string calldata identifier) external onlyOwner {
    require(bytes(registry[identifier]).length > 0, "MinosTrust: Error removing register. Identifier not found.");
    delete registry[identifier];
    emit RegisterRemoved(identifier);
  }

  /**
   * @dev Allows to transfer out the ether balance that was sent into this contract
   */
  function withdrawEther() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0, "MinosTrust: No ether available to be withdrawn");
    msg.sender.transfer(totalBalance);
  }
}