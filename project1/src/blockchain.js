const SHA256 = require('crypto-js/sha256');
const BlockClass = require('./block.js');
const bitcoinMessage = require('bitcoinjs-message');

class Blockchain { //BLOCKCHAIN CLASS
    constructor() {
        this.chain = [];
        this.height = -1;
        this.initializeChain();
    }

    async initializeChain() { //START BLOCKCHAIN WITH BLOCK GENESIS
        if( this.height === -1){
            let block = new BlockClass.Block({data: 'Genesis Block'});
            await this._addBlock(block);
        }
    }

    getChainHeight() { //RESOLVE WITH BLOCKCHAIN HEIGHT (# OF BLOCKS)
        return new Promise((resolve, reject) => {
            resolve(this.height);
        });
    }

    _addBlock(block) { //ADDS BLOCK ONTO BLOCKCHAIN
        let self = this;
        return new Promise(async (resolve, reject) => {
            block.height = self.chain.length; //ADDS BLOCK HEIGHT (# OF BLOCKS IN THE ARRAY)
            block.time = new Date().getTime().toString().slice(0,-3); //ADDS TIME NOW
            if(self.chain.length>0){ //IF NOT GENESIS BLOCK
                block.previousBlockHash = self.chain[self.chain.length-1].hash; //UPDATES PREVIOUS HASH
            }
            block.hash = SHA256(JSON.stringify(block)).toString(); //CREATES BLOCK HASH
            //VALIDATION    
            console.debug('START');
            let errors = await self.validateChain(); //INITIATES VALIDATE BLOCK METHOD
            console.log(errors)
            console.debug('END')
            if (errors.length === 0 ){ //IF NO ERRORS FOUND
                self.chain.push(block); //ADDS BLOCK
                self.height++; //UPDATES BLOCKCHAIN HEIGHT
                //console.debug(block) //CHECKS WHETHER CODE IS WORKING
                resolve(block) //RESOLVES THE NEW BLOCK
            } else{
                reject(errors); //REJECTS
            }
        });
    }

    requestMessageOwnershipVerification(address) { //REQUESTS DDRESS VERIFICATION - A LEGAGY ADDRESS IS REQUIRED
        //BITCOIN CORE: getnewaddress -addresstype legacy
        return new Promise((resolve) => {
            let message = `${address}:${new Date().getTime().toString().slice(0,-3)}:starRegistry`; //MESSAGE TO BE SIGNED
            resolve(message);
        });
    }

    submitStar(address, message, signature, star) { //POSTS STAR AND CHECKS WHETHER IT IS WITHIN THE TIME WINDOW
        let self = this;
        return new Promise(async (resolve, reject) => {
            let currentTime = parseInt(new Date().getTime().toString().slice(0, -3)); //TIME NOW
            console.debug(message) //IT WAS TRYING TO ACCESS "SELF.MESSAGE"
            //console.debug((parseInt(message.split(':')[1]) + (5*60)), currentTime)
            if ((parseInt(message.split(':')[1]) + (5*60)) > currentTime) { //IF TIME NOW LESS BLOCK TIME IS LESS THAN 5 MINUTES
                console.debug("TRANSACTION TOOK LESS THAN 5 MINUTES")
                console.debug(`"${message}"`, address, signature)
                if(bitcoinMessage.verify(`"${message}"`, address, signature)) {
                    console.debug("VERIFIED")
                    let block = new BlockClass.Block({"owner": address, "star": star}); //ADDS OWNER AND STAR PROPERTIES TO BLOCK'S BODY
                    let newBlock = await self._addBlock(block);
                    resolve(newBlock); //RESOLVES BY ADDING BLOCK
                } else {
                    console.debug("NOT VERIFIED")
                    reject(Error("SIGNATURE IS NOT VALID")) 
                }
            }
            else {
                console.debug("TRANSACTION TOOK MORE THAN 5 MINUTES")
                reject(Error("TRANSACTION TOOK MORE THAN 5 MINUTES")) 
            }
        });
    }

    getBlockByHash(hash) { //GETS BLOCK BY PASSING HASH AS ARGUMENT
        let self = this;
        return new Promise((resolve, reject) => {
            let block = self.chain.filter(p => p.hash === hash)[0]; //SEARCHES IN THE BLOCKCHAIN FOR BLOCK WITH THE HASH ARGUMENT
            if(block){
                resolve(block); //RESOLVES BLOCK
            } else {
                reject(Error("NO BLOCK FOUND")); // NO BLOCK FOUND
            }
        });
    }

    getBlockByHeight(height) { //GETS BLOCK BY PASSING HEIGHT AS ARGUMENT
        let self = this;
        return new Promise((resolve, reject) => {
            let block = self.chain.filter(p => p.height === height)[0]; //SEARCHES IN THE BLOCKCHAIN FOR BLOCK WITH THE HEIGHT ARGUMENT
            if(block){
                resolve(block); //RESOLVES BLOCK
            } else {
                resolve(null); //NO BLOCK FOUND
            }
        });
    }

    getStarsByWalletAddress (address) { //GETS STARS BY WALLET ADDRESS
        let self = this;
        let stars = []; //ARRAY OF STARS
        return new Promise((resolve, reject) => {
            self.chain.forEach(async(b) => {
                let star = await b.getBData(); //DECODE BLOCK'S BODY TO GET STAR AND OWNER
                if(star){
                    if (star.owner === address){ //IF THE OWNER HAS THE SAME WALLET ADDRESS
                        stars.push(star); //ADDS DECODED BODY INTO STARS ARRAY
                    }
                }
            });
            resolve(stars); //RESOLVES STARS ARRAY
        });
    }

    validateChain() {
        let self = this;
        let errorLog = [];
        return new Promise((resolve) => {
            let validatePromises = [];
            self.chain.forEach((block, index) => {
                if (block.height > 0) {
                    const previousBlock = self.chain[index - 1];
                    if (block.previousBlockHash !== previousBlock.hash) { //CHECKS WHETHER PREVIOUSBLOCKHASH IS DIFFERENT FROM HASH FROM BLOCK -1
                        const errorMessage = `BLOCK ${index} HAS A DIFFERENT PREVIOUSBLOCKHASH VALUE - ${block.previousBlockHash} - FROM THE ACTUAL PREVIOUS BLOCK HASH - ${previousBlock.hash}`;
                        errorLog.push(errorMessage);
                    }
                }

                //STORE PROMISSE
                validatePromises.push(block.validate());
            });
            Promise.all(validatePromises)
                .then(validatedBlocks => {
                    validatedBlocks.forEach((valid, index) => {
                        if (!valid) {
                            const invalidBlock = self.chain[index];
                            const errorMessage = `Block ${index} hash (${invalidBlock.hash}) is invalid`;
                            errorLog.push(errorMessage);
                        }
                    });
                    resolve(errorLog);
                });
        });
    }
}

module.exports.Blockchain = Blockchain;   