package org.nexml.model.impl;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

import org.nexml.model.CategoricalMatrix;
import org.nexml.model.Character;
import org.nexml.model.CharacterState;
import org.nexml.model.CharacterStateSet;
import org.nexml.model.MolecularMatrix;
import org.w3c.dom.Document;

class MolecularMatrixImpl extends
		MatrixImpl<CharacterState> implements MolecularMatrix {
	
	public MolecularMatrixImpl(Document document) {
		super(document);
	}

	private Set<CharacterStateSet> mCharacterStateSets = new HashSet<CharacterStateSet>();
	private MolecularCharacterStateSetImpl mMolecularCharacterStates = null;
	
	/**
	 * This is equivalent to creating a <states> element, i.e.
	 * a container for state elements, polymorphic_state_set elements
	 * and uncertain_state_set elements. The states elements are children
	 * of the format element (to which the matrix holds a reference).
	 * If the format element object doesn't exist yet it's created here
	 * @author rvosa
	 */
	public CharacterStateSet createCharacterStateSet() {
		CharacterStateSetImpl characterStateSet = new CharacterStateSetImpl(getDocument());
		mCharacterStateSets.add(characterStateSet);
		if ( null == getFormatElement() ) {
			setFormatElement( getDocument().createElement("format") );
			getElement().insertBefore( getFormatElement(), getElement().getFirstChild() );
		}
		getFormatElement().insertBefore( characterStateSet.getElement(), getFormatElement().getFirstChild() );
		return characterStateSet;
	}

	public Set<CharacterStateSet> getCharacterStateSets() {
		return Collections.unmodifiableSet(mCharacterStateSets);
	}
	
	/**
	 * This method creates a char element, i.e. a column definition.
	 * Because NeXML requires for categorical matrices that these
	 * column definitions have an attribute to reference the 
	 * applicable state set, the state set object needs to be passed
	 * in here, from which the attribute's value is set. 
	 * @author rvosa
	 */
	public Character createCharacter(CharacterStateSet characterStateSet) {
		CharacterImpl character = new CharacterImpl(getDocument());
		addThing(character);
		character.getElement().setAttribute("states", characterStateSet.getId());
		getFormatElement().appendChild(character.getElement());
		return character;
	}	

	public CharacterStateSet getDNACharacterStateSet() {
	    if (mMolecularCharacterStates == null){
	        mMolecularCharacterStates = new MolecularCharacterStateSetImpl(getDocument());
	    }
	    CharacterStateSet result = mMolecularCharacterStates.getDNAStateSet();
	    CharacterStateSetImpl characterStateSet = (CharacterStateSetImpl)result;
	    if (mCharacterStateSets.add(characterStateSet)){
	        if ( null == getFormatElement() ) {
	            setFormatElement( getDocument().createElement("format") );
	            getElement().insertBefore( getFormatElement(), getElement().getFirstChild() );
	        }
	        getFormatElement().insertBefore( characterStateSet.getElement(), getFormatElement().getFirstChild() );
	        mMolecularCharacterStates.fillDNAStateSet();
	    }
	    return result;
	}

	public CharacterStateSet getRNACharacterStateSet() {
        if (mMolecularCharacterStates == null){
            mMolecularCharacterStates = new MolecularCharacterStateSetImpl(getDocument());
        }
        CharacterStateSet result = mMolecularCharacterStates.getRNAStateSet();
        CharacterStateSetImpl characterStateSet = (CharacterStateSetImpl)result;
        if (mCharacterStateSets.add(characterStateSet)){
            if ( null == getFormatElement() ) {
                setFormatElement( getDocument().createElement("format") );
                getElement().insertBefore( getFormatElement(), getElement().getFirstChild() );
            }
            getFormatElement().insertBefore( characterStateSet.getElement(), getFormatElement().getFirstChild() );
            mMolecularCharacterStates.fillRNAStateSet();
        }
        return result;
     }
    
    public CharacterStateSet getProteinCharacterStateSet(){
        if (mMolecularCharacterStates == null){
            mMolecularCharacterStates = new MolecularCharacterStateSetImpl(getDocument());
        }
        CharacterStateSet result = mMolecularCharacterStates.getProteinStateSet();
        CharacterStateSetImpl characterStateSet = (CharacterStateSetImpl)result;
        if (mCharacterStateSets.add(characterStateSet)){
            if ( null == getFormatElement() ) {
                setFormatElement( getDocument().createElement("format") );
                getElement().insertBefore( getFormatElement(), getElement().getFirstChild() );
            }
            getFormatElement().insertBefore( characterStateSet.getElement(), getFormatElement().getFirstChild() );
            mMolecularCharacterStates.fillProteinStateSet();
        }
        return result;
    }

 }