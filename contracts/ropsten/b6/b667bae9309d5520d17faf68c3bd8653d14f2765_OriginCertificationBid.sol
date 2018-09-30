pragma solidity ^0.4.24;

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
    );

  function() public {
    owner = msg.sender;
    }

     modifier onlyOwner() {
    require(msg.sender == owner);
    _;
    }

   function renounceOwnership() public onlyOwner {
    OwnershipRenounced(owner);
    owner = address(0);
    }

  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
    }

  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
    }
}

// Contrato para crear los certificados de origen.
contract CreateCertification is Ownable {
    
    event NewOriginCertificate(uint OriginCertificateId, address owner, uint greenPower, uint dateOfIssue, uint duration);
    
    //Clase para los certificados de origen. 
    struct OriginCertificate {
        address owner;
        uint greenPower;
        uint dateOfIssue;
        uint duration;
    }
    
    /*Se crea array que contiene los diferentes certificados que se crean. Su posici&#243;n dentro del array se utilixar&#225; como indentificador
    del certificado de origen.*/
    OriginCertificate[] public origincertificates;
    
    //Mapping que nos indicara a quien pertenece cada certificado. 
    mapping (uint => address) public origincertificateToOwner;
    //Mapping que nos indicara cuantos certificados tiene una cuenta. Segun el modelo de negocio cada empresa puede tener solo 1 certificado. 
    mapping (address => uint) public ownerOrigincertificateCount;
    
    //Funci&#243;n para crear un certificado. Solo podr&#225; ser realizada por el "onlyOwner" que seria la agencia emisora de los certificados. 
    function createCertification(uint _greenPower, uint _duration) public onlyOwner  {
        
        uint id = origincertificates.push(OriginCertificate({owner: msg.sender, greenPower: _greenPower, dateOfIssue: now, duration: _duration})) - 1;
        origincertificateToOwner[id] = msg.sender;
        ownerOrigincertificateCount[msg.sender]++;
        
        NewOriginCertificate(id, msg.sender, _greenPower, now, _duration);
        
        
    }
}

//Contrato tipo para token ERC721. 
contract ERC721 {
    
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}



//Contrato para enviar los certificados, tipo de token ERC721
contract OriginCertificationTransfer is CreateCertification, ERC721 {
    
    //Modificador que indica que solo el propiertario de un certificado podr&#225; enviarlo. 
    modifier onlyOwnerOf(uint _certificateId) {
    require(msg.sender == origincertificateToOwner[_certificateId]);
	    _;
     }


    mapping (uint => address) certificateApprovals;

  //Funci&#243;n para ver la cantidad de certificados que tiene una direcci&#243;n.
  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerOrigincertificateCount[_owner];
    }
  //Funci&#243;n para ver a que direcci&#243;n pertenece un certificado. 
  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return origincertificateToOwner[_tokenId];
   }

  //Funci&#243;n privada para enviar los tokens (certificados) ERC 721. 
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     ownerOrigincertificateCount[_to]++;
     ownerOrigincertificateCount[_from]--;
     origincertificateToOwner[_tokenId] = _to;   
     origincertificates[_tokenId].owner = _to;

     Transfer(_from, _to, _tokenId);
    }

   //Funci&#243;n publica para enviar el certificado/token
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) { 
     _transfer(msg.sender, _to, _tokenId);
    }

  //Estas dos funciones sirven para enviar un token pero con la aprovaci&#243;n del receptor. 
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
     certificateApprovals[_tokenId] = _to;
     Approval(msg.sender, _to, _tokenId);
    }
  function takeOwnership(uint256 _tokenId) public {
      require(certificateApprovals[_tokenId] == msg.sender);
      address owner = ownerOf(_tokenId);
      _transfer(owner, msg.sender, _tokenId);
    }


}


//Contrato para subastar los certificados. 
contract OriginCertificationBid is CreateCertification, ERC721, OriginCertificationTransfer {
    
    //Clase de las subastas de los certificados. 
    struct CertificateBid {
        address beneficiary;
        uint auctionStart;
        uint biddingTime;
        uint orgincertificateId;
        address certificateOwner;
        address highestBidder;
        uint highestBid;
        bool ended;
    } 
 
    //Array donde se almacenan las diferentes subastas. Adem&#225;s la posici&#243;n de las subasta dentro del array ser&#225; su identificador. 
    CertificateBid[] public certificatebids;

    event NewCertificateBid(uint tokenId, uint certificateBidId, address beneficiary, uint auctionStart, uint biddingTime);
    event HighestBidIncreased (address bidder, uint amount);
    event BidEnded (address winner, uint amount);

    //Mapping que relaciona una direcci&#243;n con el importe a ser devuelto en caso de que su puja sea sobrepasada. 
    mapping(address => uint) public pendingReturns;
    //Mapping para relacionar el id de la subasta con una subasta.
    mapping(uint => CertificateBid) public idCertificateBids; 


   //Funci&#243;m para crear una subasta, donde solo el propietario del certificado podr&#225; hacerlo. 
    function SimpleBid(address _beneficiary, uint _biddingTime, uint _tokenId) {
        require(msg.sender == origincertificateToOwner[_tokenId]); 
        
        uint _bidId = certificatebids.push(CertificateBid(_beneficiary, now, _biddingTime, _tokenId, msg.sender, 0x0, 0, false)) -1;
        
        idCertificateBids[_bidId] = CertificateBid(_beneficiary, now, _biddingTime, _tokenId, msg.sender, 0x0, 0, false);
        
    
        NewCertificateBid(_tokenId, _bidId, msg.sender, now, _biddingTime);
        
    }
    
    //Funci&#243;n para realizar una puja a una subasta. 
    function bid(uint _bidId) payable {
        require(ownerOrigincertificateCount[msg.sender] == 0);
        require(now <= (idCertificateBids[_bidId].auctionStart + idCertificateBids[_bidId].biddingTime));
        require(msg.value > idCertificateBids[_bidId].highestBid);

        if (idCertificateBids[_bidId].highestBidder != 0) {
            pendingReturns[idCertificateBids[_bidId].highestBidder] += idCertificateBids[_bidId].highestBid;
        }

        idCertificateBids[_bidId].highestBidder = msg.sender;
        idCertificateBids[_bidId].highestBid = msg.value;

        HighestBidIncreased (msg.sender, msg.value);

    }
   
   //Funcion que permite retirar el importe de una puja si este ha sido sobrepasado. 
    function withdraw() returns (bool) {
        var amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true; 
    }

   /*Funcion para finalizar la subasta del certificado/token. Para ser finalizada ha de cumplir los tiempos.
    Una vez finalizada se enviar&#225; se enviar&#225; el dinero de la puja al beneficiario y se enviar&#225; el token a la direcci&#243;n que corresponda */
    function bidEnd(uint _bidId) {
        require(now >= (idCertificateBids[_bidId].auctionStart + idCertificateBids[_bidId].biddingTime));
        require(idCertificateBids[_bidId].ended = false); 

        idCertificateBids[_bidId].ended = true;
        
        idCertificateBids[_bidId].beneficiary.transfer(idCertificateBids[_bidId].highestBid);
        
        transfer(idCertificateBids[_bidId].highestBidder, idCertificateBids[_bidId].orgincertificateId);
        
        BidEnded (idCertificateBids[_bidId].highestBidder, idCertificateBids[_bidId].highestBid);

    }


}