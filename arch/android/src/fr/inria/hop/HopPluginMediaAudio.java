/*=====================================================================*/
/*    .../arch/android/src/fr/inria/hop/HopPluginMediaAudio.java       */
/*    -------------------------------------------------------------    */
/*    Author      :  Manuel Serrano                                    */
/*    Creation    :  Wed May 11 08:47:25 2011                          */
/*    Last change :  Mon May 30 18:28:33 2011 (serrano)                */
/*    Copyright   :  2011 Manuel Serrano                               */
/*    -------------------------------------------------------------    */
/*    Android Media Audio Plugin                                       */
/*    -------------------------------------------------------------    */
/*    This class gives access to the phone MediaAudio database.        */
/*=====================================================================*/

/*---------------------------------------------------------------------*/
/*    The package                                                      */
/*---------------------------------------------------------------------*/
package fr.inria.hop;

import android.app.*;
import android.content.*;
import android.os.*;
import android.util.Log;
import android.media.*;
import android.net.*;
import android.provider.MediaStore.Audio.*;
import android.database.Cursor;

import java.net.*;
import java.io.*;

/*---------------------------------------------------------------------*/
/*    The class                                                        */
/*---------------------------------------------------------------------*/
public class HopPluginMediaAudio extends HopPlugin {
   // private fields
   private static final String[] GENRE_LOOKUP_PROJECTION = new String[] {
      Genres._ID,
      Genres.NAME,
   };
   private static final String[] ARTIST_LOOKUP_PROJECTION = new String[] {
      Artists._ID,
      Artists.ARTIST,
   };
   private static final String[] ALBUM_LOOKUP_PROJECTION = new String[] {
      Albums._ID,
      Albums.ARTIST,
      Albums.ALBUM,
   };
   private static final String[] MEDIA_LOOKUP_PROJECTION = new String[] {
      Media._ID,
      Media.DATA,
      Media.TITLE,
      Media.MIME_TYPE,
      Media.DURATION,
      Media.TRACK,
      Media.ARTIST,
      Media.ALBUM,
   };
   
   // constructor
   public HopPluginMediaAudio( HopDroid h, Activity a, String n ) {
      super( h, a, n );
   }
   
   // plugin server
   protected void server( InputStream ip, OutputStream op )
      throws IOException {
      switch( HopDroid.read_int( ip ) ) {
	 case (byte)'G':
	    // query genres
	    Log.d( "HopPluginMediaAudio", "queryGenres" );
	    queryGenres( op );
	    break;

	 case (byte)'A':
	    // query artists
	    Log.d( "HopPluginMediaAudio", "queryArtists" );
	    queryArtists( op );
	    break;
	    
	 case (byte)'g':
	    // query artists by genre
	    Log.d( "HopPluginMediaAudio", "queryGenreArtists" );
	    queryGenreArtists( op, HopDroid.read_string( ip ) );
	    break;
	    
	 case (byte)'a':
	    // query album songs
	    Log.d( "HopPluginMediaAudio", "queryAlbum" );
	    queryAlbum( op, HopDroid.read_string( ip ) );
	    break;
	    
	 case (byte)'d':
	    // query album by artist
	    Log.d( "HopPluginMediaAudio", "queryArtistAlbum" );
	    queryArtistAlbum( op, HopDroid.read_string( ip ) );
	    break;
      }
      op.flush();

      return;
   }

   private void queryGenres( OutputStream op ) throws IOException {
      ContentResolver cr = activity.getContentResolver();
      Cursor cur = cr.query( Genres.EXTERNAL_CONTENT_URI,
			     GENRE_LOOKUP_PROJECTION,
			     null,
			     null,
			     null );
      synchronized( op ) {
	 if( cur == null ) {
	    op.write( "()".getBytes() );
	 } else {
	    op.write( "(".getBytes() );
	    if( cur.moveToFirst() ) {
	       int i = cur.getColumnIndex( Genres.NAME ); 
	       do {
		  String genre = cur.getString( i );
		  op.write( "\"".getBytes() );
		  op.write( genre.getBytes() );
		  op.write( "\" ".getBytes() );
	       } while( cur.moveToNext() );
	    }
	    op.write( ")".getBytes() );
	 }
      }
      cur.close();
   }

   private void queryArtists( OutputStream op ) throws IOException {
      ContentResolver cr = activity.getContentResolver();
      Cursor cur = cr.query( Artists.EXTERNAL_CONTENT_URI,
			     ARTIST_LOOKUP_PROJECTION,
			     null, 
			     null,
			     null );
      synchronized( op ) {
	 if( cur == null ) {
	    op.write( "()".getBytes() );
	 } else {
	    op.write( "(".getBytes() );
	    if( cur.moveToFirst() ) {
	       int i = cur.getColumnIndex( Artists.ARTIST );
	       do {
		  op.write( "\"".getBytes() );
		  op.write( cur.getString( i ).getBytes() );
		  op.write( "\" ".getBytes() );
	       } while( cur.moveToNext() );
	       
	    }
	    op.write( ")".getBytes() );
	 }
      }
      cur.close();
   }

   private void queryAlbum( OutputStream op, String album ) throws IOException {
      ContentResolver cr = activity.getContentResolver();
      Cursor cur = cr.query( Media.EXTERNAL_CONTENT_URI,
			     MEDIA_LOOKUP_PROJECTION,
			     Media.ALBUM + "='" + album + "'",
			     null,
			     null );
      synchronized( op ) {
	 if( cur == null ) {
	    op.write( "()".getBytes() );
	 } else {
	    op.write( "(".getBytes() );
	    if( cur.moveToFirst() ) {
	       int ip = cur.getColumnIndex( Media.DATA );
	       int it = cur.getColumnIndex( Media.TITLE );
	       int id = cur.getColumnIndex( Media.DURATION );
	       int in = cur.getColumnIndex( Media.TRACK );
	       int ia = cur.getColumnIndex( Media.ARTIST );
	       int iv = cur.getColumnIndex( Media.ALBUM );
	       int im = cur.getColumnIndex( Media.MIME_TYPE );
	       do {
		  op.write( "(file: \"".getBytes() );
		  op.write( cur.getString( ip ).getBytes() );
		  op.write( "\" ".getBytes() );
		  op.write( "pos: ".getBytes() );
		  op.write( cur.getString( in ).getBytes() );
		  op.write( " ".getBytes() );
		  op.write( "id: ".getBytes() );
		  op.write( cur.getString( in ).getBytes() );
		  op.write( " ".getBytes() );
		  op.write( "mime-type: ".getBytes() );
		  op.write( cur.getString( im ).getBytes() );
		  op.write( " ".getBytes() );
		  op.write( "artist: \"".getBytes() );
		  op.write( cur.getString( ia ).getBytes() );
		  op.write( "\" ".getBytes() );
		  op.write( "title: \"".getBytes() );
		  op.write( cur.getString( it ).getBytes() );
		  op.write( "\" ".getBytes() );
		  op.write( "album: \"".getBytes() );
		  op.write( cur.getString( iv ).getBytes() );
		  op.write( "\") ".getBytes() );
	       } while( cur.moveToNext() );
	       
	    }
	    op.write( ")".getBytes() );
	 }
      }
      cur.close();
   }

   private void queryArtistAlbum( OutputStream op, String artist )
      throws IOException {
      ContentResolver cr = activity.getContentResolver();
      Cursor cur = cr.query( Albums.EXTERNAL_CONTENT_URI,
			     ALBUM_LOOKUP_PROJECTION,
			     Albums.ARTIST + "='" + artist + "'", 
			     null,
			     null );
      Log.d( "HopPluginMediaAudio", "querying ArtistAlbum: [" + artist + "]");
      Log.d( "HopPluginMediaAudio", "cur=" + (cur == null ? "null" : "pas-null") );
      synchronized( op ) {
	 if( cur == null ) {
	    op.write( "()".getBytes() );
	 } else {
	    if( cur.moveToFirst() ) {
	       int j = cur.getColumnIndex( Albums.ALBUM );
		  
	       op.write( "(".getBytes() );
		  
	       do {
		  Log.d( "HopPluginMediaAudio", "ALBUM=" + cur.getString( j )    );
		  op.write( "\"".getBytes() );
		  op.write( cur.getString( j ).getBytes() );
		  op.write( "\" ".getBytes() );
	       } while( cur.moveToNext() );
	       
	       op.write( ")".getBytes() );
	    }
	 }
      }
      
      cur.close();
   }
   
   private Uri makeGenreUri( String id ) {
      return Uri.parse(
	 new StringBuilder()
	 .append( Genres.EXTERNAL_CONTENT_URI.toString() )
	 .append( "/" )
	 .append( id )
	 .append( "/" )
	 .append( Genres.Members.CONTENT_DIRECTORY )
	 .toString());
   }

   private void queryGenreArtists( OutputStream op, String genre )
      throws IOException {
      ContentResolver cr = activity.getContentResolver();
      Cursor cur = cr.query( Genres.EXTERNAL_CONTENT_URI,
			     GENRE_LOOKUP_PROJECTION,
			     Genres.NAME + "='" + genre + "'", 
			     null,
			     null );
      synchronized( op ) {
	 if( cur == null ) {
	    cur.close();
	    op.write( "()".getBytes() );
	 } else {
	    if( cur.moveToFirst() ) {
	       int i = cur.getColumnIndex( Genres._ID );
	       Cursor c = cr.query( makeGenreUri( cur.getString( i ) ),
				    new String[] { Media.ARTIST },
				    null,
				    null,
				    Media.ARTIST + " ASC" );
	       if( c.getCount() == 0 ) {
		  op.write( "()".getBytes() );
	       } else {
		  String cartist = "";
		  
		  op.write( "(".getBytes() );
		  c.moveToFirst();
		  int j = c.getColumnIndex( Media.ARTIST );
		  do {
		     String artist = c.getString( j );
		  
		     if( !artist.equals( cartist ) ) {
			op.write( "\"".getBytes() );
			op.write( artist.getBytes() );
			op.write( "\" ".getBytes() );
			cartist = artist;
		     }
		  } while( c.moveToNext() );
		  op.write( ")".getBytes() );
	       }
	       
	       c.close();
	    }
	    
	    cur.close();
	 }
      }
   }
}