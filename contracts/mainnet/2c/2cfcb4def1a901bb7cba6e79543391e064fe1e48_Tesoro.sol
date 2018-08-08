// compiler: 0.4.21+commit.dfe3193c.Emscripten.clang
pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
// Se sei un abile crypto-pirata, potrai scovare e portare a casa un tesoro da
// 1 milione di ORS tokens (equivalente a € 50.000).
// Come? Partecipa al Reservation Contract (RC) di ORS Italia & International
// versando un qualunque ammontare di ETH, preferibilmente a pi&#249; cifre
// (ad es. 1, 031158860 ETH).
//
// ORS trasferisce un importo in ETH su un suo wallet pubblico, che tutti
// possono vedere.  Ad esempio ETH 0,94627039002.
// La chiave privata la usiamo per sommarne le prime dieci cifre all’importo
// versato:
//    Wallet ORS :     0,94627039002 +
//    Chiave Privata : 0x2E1a25b98Ef5C46E4CFB3DEAdc98ce953bea0610...
//
//    Ovvero 0946270390 +
//           0212598546
//           ----------
//           1158868936
//
// Le prime 5 cifre sono il Codice Segreto per aprire il tesoro!
//
//
// Se hai versato nel RC un importo che contiene il codice segreto in sequenza,
// come in questo caso 1,031158860 ETH, allora Bingo!!!
// Avrai vinto il crypto tesoro e potrai portartelo a casa!
// In caso di pi&#249; abili pirati nel trovare il codice segreto, vincer&#225; chi avr&#224;
// la sequenza giusta nel versamento in ETH fatto in ordine di registrazione
// nel RC precedente a quella degli altri.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// If you are a skilled crypto-pirate, you can find and bring home a treasure
// of 1 million ORS tokens (equivalent to €50,000).
// How? Participate in the Reservation Contract (RC) of ORS Italia &
// International by paying any amount of ETH, preferably with several digits
// (eg 1.031158860 ETH).
//
// ORS transfers the amount to ETH on its public wallet, which everyone can
// see. For example ETH 0.94627039002.
// We use a private key to add the first ten digits to the amount paid:
//    Wallet ORS:  0.94627039002...
//    Private Key: 0x2E1a25b98Ef5C46E4CFB3DEAdc98ce953bea0610...
//
//    Or 0946270390 +
//       0212598546
//       ----------
//       1158868936
//
// The first 5 digits are the Secret code to open the treasure! If you have
// paid an amount in the RC that contains the secret code in sequence,
// as in this case 1.031158860 ETH, then Bingo !!! You will have won the crypto
// treasure and you can take it home! In case of more skilled pirates in
// finding the secret code, whoever will have the right sequence will win in
// the payment in ETH made in order of registration in the RC preceding that
// of the others.
// ----------------------------------------------------------------------------
// Communities:
//
//   IT = 0x7a7913bf973d74deb87db64136bcb63158e4ea39
//   ITP = 0x901c93f1bf70cb9a08a9716f4635c279f33ae8c7
//
// ----------------------------------------------------------------------------

contract owned {
  address public owner;

  function owned() public { owner = msg.sender; }

  function changeOwner( address newowner ) public onlyOwner {
    owner = newowner;
  }

  modifier onlyOwner {
    if (msg.sender != owner) { revert(); }
    _;
  }
}

// This contract is a mechanism to publish the private key and 5-digit magic
// number. When published, anyone will be able to inspect the contract inputs
// to determine the winning transaction

contract Tesoro is owned {

  // The Result event is emitted when this contest is &#39;over&#39; meaning someone
  // has won the prize
  //
  // Anyone can then confirm that the private key generates the public address
  // in the code below. Do this by importing the private key into any wallet.
  // The wallet will calculate and show the same public key as below.
  //
  // Then anyone can verify that the signature of the magic number matches the
  // same that is hard-coded below. Note we used geth 1.8.2-stable to generate.
  //
  // > web3.eth.sign( "<public address>", web3.sha3("<magic number>") )
  //
  // Then scan the smart contracts for all incoming transactions and find the
  // first one whose value satisfies the equation stated above.
  //
  // WARNING:
  // This should be obvious, but NEVER USE THIS PRIVATE KEY FOR ANYTHING !!

  event Result( string hexprivkey, string magicnumber );

  string public pubaddr = "0xff982b2a62eb872d01eb98761f1ff66f6055a8e6";

  string public magicnumsig = "0x28c599e8564c4e477fe69c712df9a6ad232b2dbadf77ffd9e406f1d5fa32ef7509ec26fa7fd559217ecd0d47ca04bb2d40613d0ad0b8aec2ea545baae9f763571b";

  function Tesoro() public {}

  function publish( string _hexprivkey, string _magicnumber )
  onlyOwner public {
    emit Result( _hexprivkey, _magicnumber );
  }

}