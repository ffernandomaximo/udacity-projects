const SHA256 = require('crypto-js/sha256');
const hex2ascii = require('hex2ascii');

class Block {
    // Constructor - argument data will be the object containing the transaction data
	constructor(data){
		this.hash = null;                                               // Hash of the block
		this.height = 0;                                                // Block Height (consecutive number of each block)
		this.body = Buffer.from(JSON.stringify(data)).toString('hex');  // Will contain the transactions stored in the block, by default it will encode the data
		this.time = 0;                                                  // Timestamp for the Block creation
		this.previousBlockHash = null;                                  // Reference to the previous Block Hash
    }
    
    validate() { //VALIDATES HASH VALUE
        let self = this;
        return new Promise((resolve, reject) => {
            try {
                const currentHash = self.hash; //CREATES AUXILIARY VARIABLE
                self.hash = null;
                const newHash = SHA256(JSON.stringify(self)).toString(); //RECALCULATES HASH
                self.hash = currentHash;
                resolve(currentHash === newHash); //COMPARES HASH AND RESOLVES WITH TRUE OR FALSE
            } catch (err) {
                reject(new Error(err)); //REJECTS
            }
        });
    }

    getBData() { //DECODES BLOCK'S BODY
        let self = this;
        return new Promise( async (resolve, reject) => {          
            let encoded_data = self.body;       //LOADS BLOCK'S BODY INTO DATA VARIABLE
            let decoded_data = hex2ascii(encoded_data); //DECODES BLOCK'S BODY FROM HEX TO ASCII
            let decdata_in_JSON=JSON.parse(decoded_data); //GETS JAVASCRIPT OBJECT 
            if (self.height == 0) { //IF GENESIS BLOCK
                resolve("GENESIS BLOCK"); //GENESIS BLOCK
            } else {
                resolve(decdata_in_JSON); //RESOLVES DECODED DATA
            }
        });

    }
}

module.exports.Block = Block; // Exposing the Block class as a module