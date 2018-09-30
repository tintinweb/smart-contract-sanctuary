contract gato{
    
    struct juego{
        
        
        string[3][3] miGato;
        
        
    }
    
    uint ingresa;
    
    function createGato(uint join){
        
        juego yoyo;
        for(uint i=0; i < 3 ; i++){
            for(uint j=0; j <3 ; j++){
                yoyo.miGato[i][j] = "est&#225;s loco yoyo";
            }
            
        }
            
    }
    
    function leerGat() returns(string){
      juego yoyo;
      return yoyo.miGato[0][0];
    }
}