/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

pragma solidity ^0.5.0;
// ช่วงแรกเป็นการ Register ใส่ชื่อของผู้ใช้งานว่าเป็นใครชื่ออะไร
contract GeoTrackingSystem {
    //Record each user location with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    // User fullnames / nicknames
    mapping (address => string) users;

    //Historical locations of all users เก็บโลเกชั่นของ User ทุกคน
    mapping (address => LocationStamp[]) public userLocations;

    //Register userName ก็จะบันทึกตาม private Key ของคนที่เข้ามาเป็นข้อดีของบล็อกเชนและจะลิ้งกับฟังก์ชันข้างล่าง 
    // getPublicName เฉพาะเจ้าของเท่านั้นที่ใส่ค่าได้ ฟังก์ชันสีส้ม
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }
    //Getter of userName ฟังก์ชันตัวนี้จะLink กับตัวบน ใครกดเข้ามาก็จะเป็น ผู้ใช้คนนั้น ใครๆ ก็ดูได้ ฟังก์ชั่นสี นำ้เงิน
    function getPublicName(address userAddress) public view returns (string memory){
        return users[userAddress];
    }

    function track(uint256 lat, uint256 long) public{
        LocationStamp memory currentLocation; //ที่ประกาศเป็น memory เพราะเป็นค่าที่ใส่ไว้ชั่วคราว 
        //ใส่แล้วก็จะได้หายไป เพราะมันเปลี่ยนที่อยู่ใหม่ไง ที่อยู่ก็เปลี่ยนไปเรื่อยๆ อยู่แล้ว
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = now; //block.timestamp; ใช้ได้ทั้่งสองตัวในการบอกเวลาปัจจุบัน
        userLocations[msg.sender].push(currentLocation);
    }
    //อันบนต้องบอกว่า มี Index เท่าไรซึ่งเริ่มต้นคือ 0
    //เรามาเขียนอีกฟังก์ชั่นเพื่อถามArray เฉพาะตัวสุดท้ายก็พอ เพราะบางทีมันเยอะจนเราไม่รู้ว่าเข้ามาเท่าไร
    function getLatestLocation(address userAddress) 
        public view returns (uint256 lat, uint256 long, uint256 dateTime){

        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        // return (
        // latestLocation.lat,
        // latestLocation.long,
        // latestLocation.dateTime
        // ); โค้ดของสี่บรรทัดข้างบนมีค่าเท่ากับสามบรรทัดล่าง
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}