pragma solidity ^0.4.25;

contract kikk {
    Profil[] public participants;
    string public messageSpecial;
    
    struct Profil {
        string nom;
        string linkedin;
    }
    
    constructor() {
        messageSpecial = "Merci Hassan Sefrioui! C’&#233;tait un plaisir de faire ta connaissance.";
        
        participants.push(Profil({
            nom: "Suyash Sumaroo",
            linkedin: "https://www.linkedin.com/in/suyashsumaroo/"
        }));
    }
    
    function nomParticipant(uint index) public view returns (string participant) {
        return participants[index].nom;
    }
    
    function profilParticipant(uint index) public view returns (string participant) {
        return participants[index].linkedin;
    }
    
    function messageSpecial() public view returns (string message) {
        return messageSpecial;
    }
}