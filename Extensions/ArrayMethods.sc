+ Array {
	allIsNil {
		var isNil=true;
		this.do({|i|
			if (i!=nil) {isNil=false}
		});
		^isNil;
	}
	isNilArray {
		^this.collect({|i|
			if (i==nil) {0} {1}});
	}
	interpolate { arg val;
		var valFix=val.clip(0,1);
		var n=this.size-1;
		var pmin=(valFix*n).floor;
		var pmax=(valFix*n).ceil;
		var	i=(valFix*n-pmin);
		^((this.at(pmin)*(1-i))+(this.at(pmax)*i));
	}
	mirror3 {
		^if (this.size>1) {this.mirror1} {this}
	}

}
