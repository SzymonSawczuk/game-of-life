package org.example;

import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.ResourceBundle;

import javafx.animation.Animation;
import javafx.animation.KeyFrame;
import javafx.animation.Timeline;
import javafx.event.ActionEvent;
import javafx.event.Event;
import javafx.event.EventHandler;
import javafx.event.EventType;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import javafx.util.Duration;

public class PrimaryController implements Initializable {

    @FXML
    public Button playButton;
    public VBox board;

    private Pane[][] matrix;
    private Timeline timeline;

    public void playGame(){

        timeline = new Timeline(new KeyFrame(Duration.millis(200), event -> {

            for(int i = 0; i < App.MAX; i++){
                for(int j = 0; j < App.MAX; j++){

                    int alive = 0;

                    for(int w = -1; w < 2; w++){
                        for(int k = -1; k < 2; k++){
                            String id;
                            int row = i + w;
                            int column = j + k;

                            if(row < 0)row = App.MAX - 1;
                            else if(row >= App.MAX)row = 0;
                            if(column < 0)column = App.MAX - 1;
                            else if(column >=App.MAX)column = 0;


                            id = matrix[row][column].getId();

                            if(id.equals("livingcell")){
//                                    System.out.println(((i + w)%App.MAX+App.MAX)%App.MAX);
                                alive++;
                            }
                        }
                    }
                    if(matrix[i][j].getId().equals("livingcell"))
                        alive -= 1;

//                if(alive > 0)System.out.println(alive);
                    if(matrix[i][j].getId().equals("deadcell") && alive == 3){
                        matrix[i][j].setAccessibleHelp("livingcellNext");
                    }else if(matrix[i][j].getId().equals("livingcell") && (alive !=2 && alive != 3)){
                        matrix[i][j].setAccessibleHelp("deadcellNext");
                    }else if (matrix[i][j].getId().equals("livingcell") && (alive ==2 || alive == 3)){
                        matrix[i][j].setAccessibleHelp("livingcellNext");
                    }else{
                        matrix[i][j].setAccessibleHelp("deadcellNext");
                    }

                }
            }

            for(int i = 0; i < App.MAX; i++){
                for(int j = 0; j < App.MAX; j++){
                    if(matrix[i][j].getAccessibleHelp().equals("livingcellNext"))matrix[i][j].setId("livingcell");
                    else if(matrix[i][j].getAccessibleHelp().equals("deadcellNext"))matrix[i][j].setId("deadcell");
                }
            }

        }));
        timeline.setCycleCount(Timeline.INDEFINITE);
        timeline.play();


    }

    public void stopGame(){
        if(timeline != null && timeline.getStatus().equals(Animation.Status.RUNNING)){
            System.out.println("Stop");
            timeline.stop();
        }

    }

    public void clearBoard(){
        for(int i = 0; i < App.MAX; i++){
            for(int j = 0; j < App.MAX; j++){
                matrix[i][j].setId("deadcell");
            }
        }
    }

    @Override
    public void initialize(URL url, ResourceBundle resourceBundle) {

        matrix = new Pane[App.MAX][App.MAX];

        for(int i = 0; i < App.MAX; i++){

            HBox row = new HBox();
            for(int j = 0; j < App.MAX; j++){
                Pane pixel = new Pane();
                pixel.setPrefWidth(8);
                pixel.setPrefHeight(8);
                pixel.setId("deadcell");
                pixel.addEventHandler(MouseEvent.MOUSE_CLICKED, event -> {
                    pixel.setId(pixel.getId().equals("livingcell") ? "deadcell" : "livingcell");
                });
                row.getChildren().add(pixel);
                matrix[i][j] = pixel;
            }
            board.getChildren().add(row);

        }


    }
}
