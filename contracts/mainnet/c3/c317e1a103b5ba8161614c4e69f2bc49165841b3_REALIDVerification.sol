pragma solidity ^0.4.18;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() public {owner = msg.sender; }
  modifier onlyOwner() {require(msg.sender == owner); _; }
}


contract REALIDVerification is Ownable {
    event AddVerifiedInfo(address useraddress,address orgaddress,uint8 certificateNo,string orgsign,string infoHash,string resultHash);
    event UpdateVerifiedSign(address orgaddress,address useraddress,string infoHash,uint8 certificateNo,string orgsign);
    event AddOrgInfo(address orgaddress,string certificate);
    event UpdateValidOrgInfo(address orgaddress,bool isvalid);
    event UpdateWebsiteOrg(address orgaddress,string website);

    struct verifiedInfo{
        address validOrg;
        uint8 certificateNo;
        string orgSign;
        string resultHash;
        uint256 createTime;
    }

    struct orgInfo{
        string orgName;
        string[] certificateAds;
        string website;
        bool isvalid;
        uint256 createTime;
        string country;
        uint8 level;
    }

    mapping (address => mapping (string => verifiedInfo)) internal verifiedDatas;
    mapping (address => orgInfo) internal orgData;

    function addOrg(address orgaddress,string orgName,string certificate,string website,string country, uint8 level) public onlyOwner {
        require(orgData[orgaddress].createTime == 0);
        if(bytes(certificate).length != 0){
            orgData[orgaddress].certificateAds.push(certificate);
        }
        orgData[orgaddress].orgName = orgName;
        orgData[orgaddress].website = website;
        orgData[orgaddress].isvalid = true;
        orgData[orgaddress].createTime = now;
        orgData[orgaddress].country = country;
        orgData[orgaddress].level = level;
        emit AddOrgInfo(orgaddress, certificate);
    }

    function updateValidOrg(address orgaddress,bool isvalid) public onlyOwner {
        require(orgData[orgaddress].createTime != 0);
        orgData[orgaddress].isvalid = isvalid;
        emit UpdateValidOrgInfo(orgaddress, isvalid);
    }

    function updateWebsite(address orgaddress,string website) public onlyOwner {
        require(orgData[orgaddress].createTime != 0);
        orgData[orgaddress].website = website;
        emit UpdateWebsiteOrg(orgaddress,website);
    }
    
    modifier onlyValidOrg{ require(orgData[msg.sender].isvalid);_; }
    function addOrgCertificate(string certificate) public onlyValidOrg returns(uint){
        uint certificateNo = orgData[msg.sender].certificateAds.length;
        orgData[msg.sender].certificateAds.push(certificate);
        return certificateNo;
    }



    function addVerifiedInfo(address useraddress,string infoHash,uint8 certificateNo,string orgSign,string resultHash) public onlyValidOrg {
        require(verifiedDatas[useraddress][infoHash].validOrg == address(0));
        verifiedDatas[useraddress][infoHash].validOrg = msg.sender;
        verifiedDatas[useraddress][infoHash].certificateNo = certificateNo;
        verifiedDatas[useraddress][infoHash].orgSign = orgSign;
        verifiedDatas[useraddress][infoHash].resultHash = resultHash;
        verifiedDatas[useraddress][infoHash].createTime = now;
        emit AddVerifiedInfo(useraddress,msg.sender,certificateNo,orgSign,infoHash,resultHash);
    }

    function updateVerifiedSign(address useraddress,string infoHash,uint8 certificateNo,string orgSign) public onlyValidOrg {
        require(verifiedDatas[useraddress][infoHash].validOrg == msg.sender);
        verifiedDatas[useraddress][infoHash].certificateNo = certificateNo;
        verifiedDatas[useraddress][infoHash].orgSign = orgSign;
        emit UpdateVerifiedSign(msg.sender,useraddress,infoHash,certificateNo,orgSign);
    }

    function getVerifiedInfo(address useraddress,string infoHash) view public returns(address,uint8, string, string,uint256){
        return (verifiedDatas[useraddress][infoHash].validOrg, verifiedDatas[useraddress][infoHash].certificateNo, 
        verifiedDatas[useraddress][infoHash].orgSign, verifiedDatas[useraddress][infoHash].resultHash,
        verifiedDatas[useraddress][infoHash].createTime);
    }
  
    function getOrgInfo(address org) view public returns(string,string,string,uint256,string,uint8){
        if(orgData[org].certificateAds.length == 0){
            return (orgData[org].orgName,orgData[org].website,"",orgData[org].createTime,orgData[org].country,orgData[org].level);
        }else{
            return (orgData[org].orgName,orgData[org].website,orgData[org].certificateAds[0],orgData[org].createTime,orgData[org].country,orgData[org].level);
        }
    }
    
    function getCertificateInfoByNo(address org,uint8 certificateNo) view public returns(string){
        return (orgData[org].certificateAds[certificateNo]);
    }

    function isvalidOrg(address orgaddress) view public onlyOwner returns(bool){
        return orgData[orgaddress].isvalid;
    }
}